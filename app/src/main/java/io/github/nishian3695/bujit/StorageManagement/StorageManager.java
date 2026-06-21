package io.github.nishian3695.bujit.StorageManagement;

import android.content.Context;
import android.util.Log;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;

/*
Handles reading and writing the app's main data file using Java object serialization.
Data is stored at: {filesDir}/BujitExpenseData/BujitExpenseDataBujitExpenseData
The constructor immediately opens the file and deserializes its contents into a
StorageHolder. If the file is missing, empty, or corrupt it creates a fresh default
StorageHolder so the app always starts in a valid state.
*/
public class StorageManager {
    final private String BujitExpenseData = "BujitExpenseData";
    final private File dir;
    final private File storageFile;

    private StorageHolder storageHolder;

    public StorageManager(Context context) throws ClassNotFoundException, FileNotFoundException, IOException {
        dir = new File(context.getFilesDir(), BujitExpenseData);
        storageFile = new File(dir, BujitExpenseData + BujitExpenseData);
        checkFileExistence();
        setStorageHolder();
    }

    public StorageHolder getStorageHolder() {
        return storageHolder;
    }

    public void checkFileExistence() throws IOException {
        if (!dir.exists()) {
            dir.mkdir();
        }
        if (!storageFile.exists()) {
            storageFile.createNewFile();
        }
    }

    public void setStorageHolder() throws IOException, ClassNotFoundException {
        storageHolder = new StorageHolder();
        if (storageFile.length() > 0) {
            try (ObjectInputStream ois = new ObjectInputStream(new FileInputStream(storageFile))) {
                storageHolder = (StorageHolder) ois.readObject();
            } catch (Exception e) {
                // Corrupt or incompatible file (e.g. from the old broken write path).
                // Keep the default StorageHolder set above; writeData() will overwrite the file.
                Log.e("BujitStorage", "Corrupt storage file, resetting to defaults: " + e.getMessage());
            }
        }
    }

    public void writeData(StorageHolder storageHolder) throws IOException {
        try (ObjectOutputStream oos = new ObjectOutputStream(new FileOutputStream(storageFile))) {
            oos.writeObject(storageHolder);
        }
    }
}
