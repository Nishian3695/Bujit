package io.github.nishian3695.bujit

import android.content.Context
import com.google.android.gms.tasks.Task
import com.google.android.gms.tasks.TaskCompletionSource
import com.google.android.gms.tasks.Tasks
import com.google.android.play.core.integrity.IntegrityManagerFactory
import com.google.android.play.core.integrity.StandardIntegrityManager
import com.google.firebase.appcheck.AppCheckProvider
import com.google.firebase.appcheck.AppCheckProviderFactory
import com.google.firebase.appcheck.AppCheckToken
import com.google.firebase.appcheck.FirebaseAppCheck
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors

// Release builds' App Check, ported from the Java app's StandardIntegrityAppCheckProvider:
// get a Play Integrity (Standard API) token and exchange it at the Bujit backend's
// /exchangeIntegrityToken for an App Check token. Firebase's own Play Integrity
// provider isn't used, matching the backend (which verifies the Play Integrity
// verdict itself, then mints the App Check token).
class StandardIntegrityAppCheckProvider private constructor(context: Context) : AppCheckProvider {
    private val context = context.applicationContext
    private val executor = Executors.newSingleThreadExecutor()
    @Volatile private var tokenProvider: StandardIntegrityManager.StandardIntegrityTokenProvider? = null

    override fun getToken(): Task<AppCheckToken> {
        val result = TaskCompletionSource<AppCheckToken>()
        executor.execute {
            try {
                result.setResult(exchangeWithBackend(integrityToken()))
            } catch (e: Exception) {
                result.setException(e)
            }
        }
        return result.task
    }

    private fun integrityToken(): String {
        val provider = tokenProvider ?: Tasks.await(
            IntegrityManagerFactory.createStandard(context).prepareIntegrityToken(
                StandardIntegrityManager.PrepareIntegrityTokenRequest.builder()
                    .setCloudProjectNumber(CLOUD_PROJECT_NUMBER)
                    .build()
            )
        ).also { tokenProvider = it }
        return Tasks.await(
            provider.request(StandardIntegrityManager.StandardIntegrityTokenRequest.builder().build())
        ).token()
    }

    private fun exchangeWithBackend(integrityToken: String): AppCheckToken {
        val connection = URL(EXCHANGE_URL).openConnection() as HttpURLConnection
        connection.connectTimeout = 15_000
        connection.readTimeout = 15_000
        connection.requestMethod = "POST"
        connection.setRequestProperty("Content-Type", "application/json")
        connection.doOutput = true
        connection.outputStream.use {
            it.write(JSONObject().put("integrityToken", integrityToken).toString().toByteArray(Charsets.UTF_8))
        }
        val code = connection.responseCode
        val body = (if (code < 400) connection.inputStream else connection.errorStream)
            .bufferedReader(Charsets.UTF_8).use { it.readText() }
        if (code != 200) throw IllegalStateException("exchangeIntegrityToken HTTP $code: $body")
        val json = JSONObject(body)
        return Token(json.getString("token"), System.currentTimeMillis() + json.optLong("ttlMillis", 3_600_000L))
    }

    private class Token(private val token: String, private val expireTimeMillis: Long) : AppCheckToken() {
        override fun getToken(): String = token
        override fun getExpireTimeMillis(): Long = expireTimeMillis
    }

    companion object {
        private const val CLOUD_PROJECT_NUMBER = 533939418471L // project bujit-89ac6
        private const val EXCHANGE_URL = "https://tellerproxy-kswzrkdipq-uc.a.run.app/exchangeIntegrityToken"

        fun factory(): AppCheckProviderFactory =
            AppCheckProviderFactory { app -> StandardIntegrityAppCheckProvider(app.applicationContext) }
    }
}

// Called from Dart once Firebase is initialized (see MainActivity).
object ReleaseAppCheck {
    fun install(): Boolean {
        FirebaseAppCheck.getInstance().installAppCheckProviderFactory(StandardIntegrityAppCheckProvider.factory())
        return true
    }
}
