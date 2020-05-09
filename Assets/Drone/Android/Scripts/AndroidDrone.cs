using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AndroidDrone : Drone
{
  
    AndroidJavaObject droneNativeObject;

    private GPSState gpsState = new GPSState();

    public AndroidDrone(AndroidJavaObject droneNativeObject) {
        this.droneNativeObject = droneNativeObject;
        
    }

    protected override string GetModelName() {
        return droneNativeObject.Call<string>("GetModelName");
    }

    static Texture2D videoStreamTexture;
    protected override Texture2D StartVideoStream_Native() {
        int width = droneNativeObject.Get<int>("width");
        int height = droneNativeObject.Get<int>("height");

        if (videoStreamTexture == null)
            videoStreamTexture = new Texture2D(width, height, TextureFormat.RGBA32, false);

        droneNativeObject.Call("StartStream", videoStreamTexture.GetNativeTexturePtr().ToInt32()/*, 1920, 1088*/);
        return videoStreamTexture;
    }

    protected override void StopVideoStream_Native() {
        droneNativeObject.Call("StopStream");
       /* if (videoStreamTexture != null) {
            UnityEngine.Object.DestroyImmediate(videoStreamTexture);
            videoStreamTexture = null;
        }*/
    }

    public override void Update() {
        base.Update();

        if (IsStreaming && droneNativeObject != null &&videoStreamTexture != null) {
            var frame = droneNativeObject.Call<AndroidJavaObject>("GetCameraFrame");
            if (frame == null)
                return;

            byte[] bytes = frame.Get<byte[]>("jpegFrame");
            int width = frame.Get<int>("width");
            int height = frame.Get<int>("height");

           /* if (videoStreamTexture.width != width || videoStreamTexture.height != height) {
                //Debug.Log($"resize: width {videoStreamTexture.width} to {width} | height {videoStreamTexture.height} to {height}");
                videoStreamTexture.Resize(width, height);
            }
            */
            if (bytes != null && bytes.Length > 0) {
                //Debug.Log("texture size: width " + videoStreamTexture.width + " height " + videoStreamTexture.height);
                videoStreamTexture.LoadRawTextureData(bytes);
                videoStreamTexture.Apply(false);
            }
        }
        
    }

    public override float GetDroneHeading() {
        return droneNativeObject.Call<float>("GetHeading");
    }

    public override GPSState GetGPSState() {
        var droneFlightState = droneNativeObject.Call<AndroidJavaObject>("GetDroneFlightState");

        bool isFlying = droneFlightState.Get<bool>("isFlying");
        float droneAltitudeFromGround = droneFlightState.Get<float>("altitudeFromGround");

        if (isFlying) {
            var takeoffAltitude = droneFlightState.Get<float>("takeofLocationAltitude");
            if (float.IsNaN(takeoffAltitude)) {
               // takeoffAltitude = LocationProviderFactory.Instance.DefaultLocationProvider.CurrentLocation.Altitude;
            }
            gpsState.altitude = droneAltitudeFromGround + takeoffAltitude;
        }
        else {
           // gpsState.altitude = droneAltitudeFromGround + LocationProviderFactory.Instance.DefaultLocationProvider.CurrentLocation.Altitude;
        }

        gpsState.signalLevel = droneFlightState.Get<int>("signalLevel");
        gpsState.latitude = droneFlightState.Get<double>("latitude");
        gpsState.longitude = droneFlightState.Get<double>("longitude");
        gpsState.satelliteCount = droneFlightState.Get<int>("satelliteCount");

        return gpsState;
    }

    public override Quaternion GetDroneRotation() {
        var attitude = droneNativeObject.Call<float[]>("GetDroneAttitude");
        if (attitude == null)
            return Quaternion.identity;
        return Quaternion.Euler(-attitude[0], attitude[1], attitude[2]);
    }

    public override Quaternion GetDroneCameraRotation() {
        var attitude = droneNativeObject.Call<float[]>("GetGimbalAttitude");
        if (attitude == null)
            return Quaternion.identity;
        return Quaternion.Euler(-attitude[0], attitude[1], attitude[2]);
    }
}
