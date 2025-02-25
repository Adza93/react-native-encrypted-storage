/* eslint-disable no-dupe-class-members */
import { NativeModules } from 'react-native';
const {
  RNEncryptedStorage
} = NativeModules;

if (!RNEncryptedStorage) {
  throw new Error('RNEncryptedStorage is undefined');
}

export default class EncryptedStorage {
  /**
   * Writes data to the disk, using SharedPreferences or KeyChain, depending on the platform.
   * @param {string} key - A string that will be associated to the value for later retrieval.
   * @param {string} value - The data to store.
   */

  /**
   * Writes data to the disk, using SharedPreferences or KeyChain, depending on the platform.
   * @param {string} key - A string that will be associated to the value for later retrieval.
   * @param {string} value - The data to store.
   * @param {Function} cb - The function to call when the operation completes.
   */
  static setItem(key, value, cb) {
    if (cb) {
      RNEncryptedStorage.setItem(key, value).then(cb).catch(cb);
      return;
    }

    return RNEncryptedStorage.setItem(key, value);
  }
  /**
   * Retrieves data from the disk, using SharedPreferences or KeyChain, depending on the platform and returns it as the specified type.
   * @param {string} key - A string that is associated to a value.
   */


  static getItem(key, cb) {
    if (cb) {
      RNEncryptedStorage.getItem(key).then(cb).catch(cb);
      return;
    }

    return RNEncryptedStorage.getItem(key);
  }
  /**
   * Deletes data from the disk, using SharedPreferences or KeyChain, depending on the platform.
   * @param {string} key - A string that is associated to a value.
   */


  static removeItem(key, cb) {
    if (cb) {
      RNEncryptedStorage.removeItem(key).then(cb).catch(cb);
      return;
    }

    return RNEncryptedStorage.removeItem(key);
  }
  /**
   * Clears all data from disk, using SharedPreferences or KeyChain, depending on the platform.
   */


  static clear(cb) {
    if (cb) {
      RNEncryptedStorage.clear().then(cb).catch(cb);
      return;
    }

    return RNEncryptedStorage.clear();
  }

  /* AAC 23.06.21 */
  static getAllKeys(cb) {
    if (cb) {
      RNEncryptedStorage.getAllKeys().then(cb).catch(cb);
      return;
    }

    return RNEncryptedStorage.getAllKeys(key);
  }

  /* AAC 15.08.23 */
  static getAllKeysAndValues(cb) {
    if (cb) {
      RNEncryptedStorage.getAllKeysAndValues().then(cb).catch(cb);
      return;
    }

    return RNEncryptedStorage.getAllKeysAndValues(key);
  }

}
//# sourceMappingURL=EncryptedStorage.js.map