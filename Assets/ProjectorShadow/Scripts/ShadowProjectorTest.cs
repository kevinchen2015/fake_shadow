using UnityEngine;
using System.Collections.Generic;

[ExecuteInEditMode]
public class ShadowProjectorTest : MonoBehaviour 
{
    public Camera _mainCamera;
    public Transform _lightFollowTrans;    //跟随镜头的某个合适的相对位置，或者主角的位置

    public Transform _showClipCenter;      //镜头跟随的主角trans
    public float _shaderClipDistance = 40; //作为优化裁剪镜头的距离

    public Shader shadowReplaceShader;

    private Camera _lightCamera;
    private Projector _projector;
    private RenderTexture _shadowTex;
    private Transform _lightSelfTrans;

    void Start () 
    {
        _projector = GetComponent<Projector>();
        _lightCamera = GetComponent<Camera>();

        _lightCamera.orthographic = true;
        _lightCamera.cullingMask = LayerMask.GetMask("ShadowCaster");
        _lightCamera.clearFlags = CameraClearFlags.SolidColor;
        _lightCamera.backgroundColor = new Color(0,0,0,0);

        _shadowTex = new RenderTexture(512, 512, 0, RenderTextureFormat.ARGB32);
        _shadowTex.filterMode = FilterMode.Bilinear;
        _lightCamera.targetTexture = _shadowTex;

        _lightCamera.SetReplacementShader(shadowReplaceShader, "RenderType");
        _projector.material.SetTexture("_ShadowTex", _shadowTex);
        _projector.ignoreLayers = LayerMask.GetMask("ShadowCaster");

        _lightSelfTrans = _lightCamera.transform;
    }

    void LateUpdate()
    {
        _lightCamera.transform.position = _lightFollowTrans.position;

        _projector.aspectRatio = _lightCamera.aspect;
        _projector.orthographicSize = _lightCamera.orthographicSize;
        _projector.nearClipPlane = _lightCamera.nearClipPlane;
        _projector.farClipPlane = _lightCamera.farClipPlane;
	}

    public void ShadowProjectorEnable(bool enable)
    {
        this.enabled = enable;
        _lightCamera.enabled = enabled;
        _projector.enabled = enabled;
    }

    public bool IsShadowProjectorEnable()
    {
        return enabled;
    }

    public bool IsInShadowArea(Vector3 pos)
    {
        if (enabled) return false;

        float dx = Mathf.Abs(pos.x - _showClipCenter.position.x);
        float dz = Mathf.Abs(pos.z - _showClipCenter.position.z);

        if(dx < _shaderClipDistance || dz < _shaderClipDistance)
        {
            return true;
        }
        return false;
    }
    
}
