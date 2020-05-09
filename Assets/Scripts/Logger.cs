using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class Logger : SingleInstance<Logger>
{
    const int MAX_LINES = 25;

    [SerializeField] Text text;

    List<string> lines = new List<string>();

    private void Awake() {
        text.text = "";
        Application.logMessageReceived += OnLogMessageReceived;
    }

    private void OnLogMessageReceived(string condition, string stackTrace, LogType type) {
        if (type == LogType.Error || type == LogType.Exception)
            Log($"<color=#FF0000>{condition}</color>");
    }

    public void Clear() {
        lines.Clear();
        lines.Add("Cleared " + DateTime.Now);
        WriteLines();
    }

    public void Log(string s) {
        lines.Add(s);
        while(lines.Count > MAX_LINES) {
            lines.RemoveAt(0);
        }
        WriteLines();
    }

    void WriteLines() {
        string s = "";
        foreach (var line in lines)
            s += line + "\n";
        text.text = s;
    }

}
