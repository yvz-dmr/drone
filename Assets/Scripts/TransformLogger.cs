using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class TransformLogger : MonoBehaviour
{
    public Transform[] transforms;
    public Text text;

    void Update()
    {
        string s = "";
        foreach(var t in transforms) {
            s += t.name + " Pos: " + t.localPosition + " Rot:" + t.localRotation.eulerAngles + "\n";
        }
        text.text = s;
    }
}
