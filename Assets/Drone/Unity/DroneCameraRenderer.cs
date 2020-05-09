using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class DroneCameraRenderer : MonoBehaviour
{
    [SerializeField] RawImage rawImage;
    [SerializeField] AspectRatioFitter ratioFitter;
    [SerializeField] Camera cam;

    public AspectRatioFitter.AspectMode fitMode = AspectRatioFitter.AspectMode.EnvelopeParent;

    private Texture2D _texture;
    private int _textureWidth;
    private int _textureHeight;

    void Start()
    {
        rawImage.enabled = false;
        if(DroneSession.Instance.IsDroneConnected) {
            StartStream();
        }

        DroneSession.Instance.OnDroneConnectedEvent.AddListener(StartStreamOnDroneConnection);
        DroneSession.Instance.OnDroneDisconnectedEvent.AddListener(StopStream);

#if UNITY_ANDROID
        rawImage.transform.localScale = new Vector3(1, -1, 1);
#endif

    }

    void StartStreamOnDroneConnection(Drone d) {
        StartStream();
    }

    private void OnDestroy() {
        if(DroneSession.Instance != null) {
            DroneSession.Instance.OnDroneConnectedEvent.RemoveListener(StartStreamOnDroneConnection);
            DroneSession.Instance.OnDroneDisconnectedEvent.RemoveListener(StopStream);
        }
        StopStream();
    }

    public void StopStream() {
        rawImage.enabled = false;
        if (DroneSession.Instance != null)
            DroneSession.Instance.Drone?.StopVideoStream();
    }

    private void Update() {
        if (_texture != null && (_texture.width != _textureWidth || _texture.height != _textureHeight)) {
            ReCalculateAspectRatio();
        }
    }

    public async void ReCalculateAspectRatio() {
        var texture = rawImage.texture;
        if (texture != null) {
            _textureWidth = texture.width;
            _textureHeight = texture.height;
            ratioFitter.aspectMode = AspectRatioFitter.AspectMode.EnvelopeParent;
            ratioFitter.aspectRatio = texture.width / (float)texture.height;
        }
    }

    public void StartStream() {
        rawImage.enabled = true;
        _texture = DroneSession.Instance.Drone.StartVideoStream();
        rawImage.texture = _texture;
        ReCalculateAspectRatio();
    }
}
