#if UNITY_IOS || UNITY_EDITOR

using UnityEngine;
using UnityEditor;
using UnityEditor.Callbacks;
using System.Collections;
using UnityEditor.iOS.Xcode;
using System.IO;

public class DroneXcodeProjectAutomater : Editor {

    [PostProcessBuild]
    public static void UpdateProjectFiles(BuildTarget buildTarget, string pathToBuiltProject) {
        if (buildTarget == BuildTarget.iOS) {
            UpdateInfoPlist(pathToBuiltProject);
            CreatePodFile(pathToBuiltProject);
        }
    }

    static void UpdateInfoPlist(string projectPath) {
        // Get plist
        string plistPath = projectPath + "/Info.plist";
        PlistDocument plist = new PlistDocument();
        plist.ReadFromString(File.ReadAllText(plistPath));

        // Get root
        PlistElementDict rootDict = plist.root;

        // Change value of CFBundleVersion in Xcode plist
        var array = rootDict.CreateArray("UISupportedExternalAccessoryProtocols");
        array.AddString("com.dji.video");
        array.AddString("com.dji.protocol");
        array.AddString("com.dji.common");

        rootDict.SetString("DJISDKAppKey", GetConfigFile().iosAppKey);

        rootDict.SetString("NSBluetoothAlwaysUsageDescription", "Drone bağlantısı için kullanılacaktır");

        // Write to file
        File.WriteAllText(plistPath, plist.WriteToString());
    }

    static void CreatePodFile(string projectPath) {
        var podFileRaw = GetConfigFile().podFile.text;
        var podFileFinal =  podFileRaw.Replace("*iosVersion*", PlayerSettings.iOS.targetOSVersionString);
        File.WriteAllText(projectPath + "/Podfile", podFileFinal);
    }

    static DJIConfiguration GetConfigFile() {
        const string NO_ASSET_FILE_ERROR = nameof(DJIConfiguration) + " couldn't be found as an asset! it is needed to drone functionalities to work in ios platform";

        var assets = AssetDatabase.FindAssets($"t:{nameof(DJIConfiguration)}");
        if (assets == null || assets.Length == 0) {
            Debug.LogError(NO_ASSET_FILE_ERROR);
            return null;
        }

        var assetGUID = assets[0];
        var configPath = AssetDatabase.GUIDToAssetPath(assetGUID);
        var configFile = AssetDatabase.LoadAssetAtPath<DJIConfiguration>(configPath);

        if (configFile == null) {
            Debug.LogError(NO_ASSET_FILE_ERROR);
            return null;
        }

        return configFile;
    }
}

#endif
