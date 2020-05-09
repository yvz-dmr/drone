using System.Collections;
using System.Collections.Generic;
using UnityEngine;


[System.Serializable]
public abstract class Drone {

    public static Drone Instance { get; private set; }

    public class GPSState {
        public int signalLevel;
        public double latitude;
        public double longitude;
        public float altitude;
        public int satelliteCount;

        public override string ToString() {
            return $"{nameof(signalLevel)}: {signalLevel}, {nameof(latitude)}: {latitude}, {nameof(longitude)}: {longitude}, {nameof(altitude)}: {altitude}, {nameof(satelliteCount)}: {satelliteCount}";
        }
    }

    public Drone() {
        Instance = this;
    }

    string name;
    public string Name {
        get {
            if (string.IsNullOrEmpty(name))
                name = GetModelName();
            return name;
        }
    }

    public bool IsStreaming { get; private set; }

    private Texture2D videoStreamTexture;
    public Texture2D StartVideoStream() {
        if (IsStreaming)
            return videoStreamTexture;


        IsStreaming = true;
        videoStreamTexture = StartVideoStream_Native();
        return videoStreamTexture;
    }

    public void StopVideoStream() {
        if (!IsStreaming)
            return;

        IsStreaming = false;
        StopVideoStream_Native();
        videoStreamTexture = null;
    }

    /// <summary>
    /// Drone's model name provided by dji sdk
    /// </summary>
    /// <returns></returns>
    protected abstract string GetModelName();

    /// <summary>
    /// Starts live video stream from drone and writes it to texture
    /// </summary>
    /// <param name="texture"></param>
    protected abstract Texture2D StartVideoStream_Native();

    /// <summary>
    /// Stops live video stream
    /// </summary>
    protected abstract void StopVideoStream_Native();

    /// <summary>
    /// 
    /// </summary>
    /// <returns></returns>
    public abstract GPSState GetGPSState();

    /// <summary>
    /// Drone heading according to geographical north
    /// </summary>
    /// <returns></returns>
    public abstract float GetDroneHeading();

    public abstract Quaternion GetDroneRotation();
    public abstract Quaternion GetDroneCameraRotation();

    public virtual void Update() {

    }

}
