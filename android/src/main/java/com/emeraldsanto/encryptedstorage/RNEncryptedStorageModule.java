package com.emeraldsanto.encryptedstorage;

import android.content.Context;
import android.content.SharedPreferences;
import android.util.Log;
import androidx.security.crypto.EncryptedSharedPreferences;
import androidx.security.crypto.MasterKey;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableNativeArray;
import java.util.List;
import java.util.HashMap;

import org.json.JSONObject;

import java.util.Iterator;
import java.util.Map;
import java.util.ArrayList;

public class RNEncryptedStorageModule extends ReactContextBaseJavaModule {

    private static final String NATIVE_MODULE_NAME = "RNEncryptedStorage";
    private static final String SHARED_PREFERENCES_FILENAME = "RN_ENCRYPTED_STORAGE_SHARED_PREF";

    private SharedPreferences sharedPreferences;

    public RNEncryptedStorageModule(ReactApplicationContext context) {
        super(context);

        try {
            MasterKey key = new MasterKey.Builder(context)
                    .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                    .build();

            this.sharedPreferences = EncryptedSharedPreferences.create(
                context,
                RNEncryptedStorageModule.SHARED_PREFERENCES_FILENAME,
                key,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            );
        }

        catch (Exception ex) {
            Log.e(NATIVE_MODULE_NAME, "Failed to create encrypted shared preferences! Failing back to standard SharedPreferences", ex);
            this.sharedPreferences = context.getSharedPreferences(RNEncryptedStorageModule.SHARED_PREFERENCES_FILENAME, Context.MODE_PRIVATE);
        }
    }

    @Override
    public String getName() {
        return RNEncryptedStorageModule.NATIVE_MODULE_NAME;
    }

    @ReactMethod
    public void setItem(String key, String value, Promise promise) {
        if (this.sharedPreferences == null) {
            promise.reject(new NullPointerException("Could not initialize SharedPreferences"));
            return;
        }

        SharedPreferences.Editor editor = this.sharedPreferences.edit();
        editor.putString(key, value);
        boolean saved = editor.commit();

        if (saved) {
            promise.resolve(value);
        }

        else {
            promise.reject(new Exception(String.format("An error occurred while saving %s", key)));
        }
    }

    @ReactMethod
    public void getItem(String key, Promise promise) {
        if (this.sharedPreferences == null) {
            promise.reject(new NullPointerException("Could not initialize SharedPreferences"));
            return;
        }

        String value = this.sharedPreferences.getString(key, null);

        promise.resolve(value);
    }

    @ReactMethod
    public void getAllKeys(Promise promise) {
        if (this.sharedPreferences == null) {
            promise.reject(new NullPointerException("Could not initialize SharedPreferences"));
            return;
        }

        Map<String, ?> allData = this.sharedPreferences.getAll();
        WritableNativeArray keyArray = new WritableNativeArray();
        for (Map.Entry<String, ?> entry : allData.entrySet()) {
            //Log.d("map values", entry.getKey() + ": " + entry.getValue().toString());
            keyArray.pushString(entry.getKey());
        }

        promise.resolve(keyArray);
    }

    @ReactMethod
    public void getAllKeysAndValues(Promise promise) {
        if (this.sharedPreferences == null) {
            promise.reject(new NullPointerException("Could not initialize SharedPreferences"));
            return;
        }

        Map<String, ?> allData = this.sharedPreferences.getAll();
        List<Map<String, String>> keyValuePairs = new ArrayList<>();
        for (Map.Entry<String, ?> entry : allData.entrySet()) {
            String key = entry.getKey();
            String value = entry.getValue().toString();

            Map<String, String> keyValuePair = new HashMap<>();
            keyValuePair.put("key", key);
            keyValuePair.put("value", value);
            keyValuePairs.add(keyValuePair);
        }

        promise.resolve(keyValuePairs);
    }

    @ReactMethod
    public void save(String latestSecureStorageData, Promise promise) {
        if (this.sharedPreferences == null) {
            promise.reject(new NullPointerException("Could not initialize SharedPreferences"));
            return;
        }

        SharedPreferences.Editor editor = this.sharedPreferences.edit();
        try{
            JSONObject secureStorageObject = new JSONObject(latestSecureStorageData);
            Iterator<String> keys = secureStorageObject.keys();
            while(keys.hasNext()) {
                String key = keys.next();
                editor.putString(key, secureStorageObject.getString(key));
                //Commit changes to secure storage
                editor.commit();
            }
        }
        catch(Exception e){
            promise.reject(new Exception("Error while parsing new secure storage data!"));
        }
        promise.resolve(true);
    }


    @ReactMethod
    public void removeItem(String key, Promise promise) {
        if (this.sharedPreferences == null) {
            promise.reject(new NullPointerException("Could not initialize SharedPreferences"));
            return;
        }

        SharedPreferences.Editor editor = this.sharedPreferences.edit();
        editor.remove(key);
        boolean saved = editor.commit();

        if (saved) {
            promise.resolve(key);
        }

        else {
            promise.reject(new Exception(String.format("An error occured while removing %s", key)));
        }
    }

    @ReactMethod
    public void clear(Promise promise) {
        if (this.sharedPreferences == null) {
            promise.reject(new NullPointerException("Could not initialize SharedPreferences"));
            return;
        }

        SharedPreferences.Editor editor = this.sharedPreferences.edit();
        editor.clear();
        boolean saved = editor.commit();

        if (saved) {
            promise.resolve(null);
        }

        else {
            promise.reject(new Exception("An error occured while clearing SharedPreferences"));
        }
    }
}
