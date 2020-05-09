using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = nameof(DJIConfiguration), menuName = "DJI/" + nameof(DJIConfiguration))]
public class DJIConfiguration : ScriptableObject
{
    public string AppKey {
        get {
#if UNITY_IOS
            return iosAppKey;
#endif
            return null;
        }
    }

    [Header("iOS")]
    public string iosAppKey;
    public TextAsset podFile;

}
