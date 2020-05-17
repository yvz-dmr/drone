#if (UNITY_IPHONE && !UNITY_EDITOR)
#define IS_IOS_PLATFORM
#endif

using UnityEngine;
using System.Runtime.InteropServices;

public class IOSDrone : Drone
{

    [DllImport("__Internal")]
    private static extern void      _DJI_StartVideoStream();
    [DllImport("__Internal")]
    private static extern void      _DJI_StopVideoStream();
    [DllImport("__Internal")]
    private static extern float     _GetDroneHeading(string key);
    [DllImport("__Internal")]
    private static extern string    _GetModelName(string key);
    [DllImport("__Internal")]
    private static extern bool      _IsFlying(string key);
    [DllImport("__Internal")]
    private static extern float     _GetAltitudeFromGround(string key);
    [DllImport("__Internal")]
    private static extern float     _GetTakeofLocationAltitude(string key);
    [DllImport("__Internal")]
    private static extern int       _GetSignalLevel(string key);
    [DllImport("__Internal")]
    private static extern int       _GetSatelliteCount(string key);
    [DllImport("__Internal")]
    private static extern double    _GetLatitude(string key);
    [DllImport("__Internal")]
    private static extern double    _GetLongitude(string key);
    [DllImport("__Internal")]
    private static extern string    _GetDroneAttitude(string key);
    [DllImport("__Internal")]
    private static extern string    _GetGimbalAttitude(string key);

    [DllImport("__Internal")]
    private static extern byte[] _getTextureOption1();

    protected bool _IsFailedToParse = false;
    protected bool _IsVideoStreamData = false;
    private  string CameraFrameData { get; set; }

    // #region GetModelName
    // /// <summary>
    // /// Here is another method for getting DJI Model Name
    // /// This method is based on Observer Pattern. When some thing changed in native end, 
    // /// It will reflect in Unity end.
    // /// </summary>
    // /// Delegate Method
    // public string _GetModelNameFromNative;

    // public delegate void DroneModelCallbackFunc(string modelName);

    // [DllImport("__Internal")]
    // private static extern void _DJI_ModelName(DroneModelCallbackFunc callbackFunc);

    // [AOT.MonoPInvokeCallback(typeof(DroneModelCallbackFunc))]
    // private static void DroneModelNameDidChange(string modelName)
    // {
    //     /// Recieve callback data when change happen in native end.
    //     IOSScreenWriter.Write("ModelName:- "+modelName);
    //     _GetModelNameFromNative = modelName;
    // }
    // #endregion


    public IOSDrone()
    {
    }

    private GPSState gpsState = new GPSState();

    protected override string GetModelName()
    {
        return _GetModelName("GetModelName");
    }

    // protected override string GetModelName2()
    // {
    //     return _GetModelNameFromNative;
    // }

    // why changed ? Need to think how to do this ; still not found solution 
    // to return texture from iOS, this link gives some hint but cant try as i dont have drone : https://github.com/edom18/NativePluginCopyTexture
    
    static Texture2D videoStreamTexture;
    protected override Texture2D StartVideoStream_Native()
    {
        if (videoStreamTexture == null)
            videoStreamTexture = new Texture2D(Screen.width, Screen.height, TextureFormat.RGBA32, false);

        //droneNativeObject.Call("StartStream", videoStreamTexture.GetNativeTexturePtr().ToInt32()/*, 1920, 1088*/);
        return videoStreamTexture;
    }

    protected override void StopVideoStream_Native()
    {
        _DJI_StopVideoStream();
    }

    public override void Update()
    {
        base.Update();

        if (IsStreaming && !_IsFailedToParse && _IsVideoStreamData)
        {
            byte[] videoByte = _getTextureOption1();
            byte[] decodedFromBase64 = System.Convert.FromBase64String(CameraFrameData);

            if (videoByte != null && videoByte.Length > 0)
            {
                videoStreamTexture.LoadRawTextureData(videoByte);
                videoStreamTexture.Apply(false);
            }
        }
    }

    public override float GetDroneHeading()
    {
        return _GetDroneHeading("GetHeading");
    }

    public override GPSState GetGPSState()
    {
        bool isFlying = _IsFlying("isFlying");
        float droneAltitudeFromGround = _GetAltitudeFromGround("altitudeFromGround");

        if (isFlying)
        {
            var takeoffAltitude = _GetTakeofLocationAltitude("takeofLocationAltitude");
            Debug.Log("Uncomment GetGPSState Location Provider code in real project");
            if (float.IsNaN(takeoffAltitude))
            {
             //   takeoffAltitude = LocationProviderFactory.Instance.DefaultLocationProvider.CurrentLocation.Altitude;
            }
            gpsState.altitude = droneAltitudeFromGround + takeoffAltitude;
        } else {
           // gpsState.altitude = droneAltitudeFromGround + LocationProviderFactory.Instance.DefaultLocationProvider.CurrentLocation.Altitude;
        }

        gpsState.signalLevel    = _GetSignalLevel("signalLevel");
        gpsState.latitude       = _GetLatitude("latitude");
        gpsState.longitude      = _GetLongitude("longitude");
        gpsState.satelliteCount = _GetSatelliteCount("satelliteCount");

        return gpsState;
    }

    public override Quaternion GetDroneRotation()
    {
        var attitude = _SerializeStringsArray(_GetDroneAttitude("GetDroneAttitude"));
        if (attitude == null)
            return Quaternion.identity;
        return Quaternion.Euler(-attitude[0], attitude[1], attitude[2]);
    }

    public override Quaternion GetDroneCameraRotation()
    {
        var attitude = _SerializeStringsArray(_GetGimbalAttitude("GetGimbalAttitude"));
        if (attitude == null)
            return Quaternion.identity;
        return Quaternion.Euler(-attitude[0], attitude[1], attitude[2]);
    }

    /// <summary>
    /// After Getting Successfully Video Stream data
    /// </summary>
    /// <param name="data"></param>
    public void OnVideoStreamSuccessWithData(string data)
    {
        if (data.Length == 0)
        {
            return;
        }
        _IsVideoStreamData = true;
        CameraFrameData = data;
    }

    /// <summary>
    /// This Get called when Drone data is not available
    /// </summary>
    /// <param name="message"></param>
    public void OnDroneDataNotAvailable(string message)
    {
        Logger.Instance.Log(message);
    }

    /// <summary>
    /// This Get called when Camera Stream setup failed
    /// </summary>
    /// <param name="message"></param>
    public void OnVideoStreamFailed(string message)
    {
        Logger.Instance.Log(message);
    }

    private float[] _SerializeStringsArray(string text)
    {
        return System.Array.ConvertAll(text.Split('|'), float.Parse);
    }
}
