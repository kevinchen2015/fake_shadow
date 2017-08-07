#warning Upgrade NOTE: unity_Scale shader variable was removed; replaced 'unity_Scale.w' with '1.0'
// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Unlit shader. Simplest possible textured shader.
// - SUPPORTS lightmap
// - no lighting
// - no per-material color

Shader "simple" {
Properties {
	_Color ("Main Color", Color) = (0.5,0.5, 0.5,1.0)
	_MainTex ("Base (RGB)", 2D) = "white" {}

	_ShadowPlane("Shadow Plane", vector) = (0,1,0,0)
	_ShadowProjDir("ShadowProjDir", vector) = (-1,0,0,-1)
	_ShadowFadeParams("ShadowFadeParams", vector) = (0,0,0,0)
	_ShadowInvLen("ShadowInvLen", float) = 0.2

}

// high
SubShader {
	Tags { "RenderType"="Opaque" "LightMode"="ForwardBase" "Queue"="Transparent-400" }
	LOD 300
	
	Lighting Off
	Fog { Mode Off }

	CGINCLUDE
	#include "UnityCG.cginc"
	ENDCG	
	
	Pass {
		Name "ForwardBase"

		Cull Back

		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#pragma fragmentoption ARB_precision_hint_fastest	

	
		uniform sampler2D _MainTex; 


		half4 _MainTex_ST;
		uniform fixed4 _Color;

		struct VertexInput {
	        float4 vertex : POSITION;
	        half2 texcoord : TEXCOORD0;
			
	    };
	    struct VertexOutput {
	        float4 pos : SV_POSITION;
	        half2 uv : TEXCOORD0;
	    };
	    
	    VertexOutput vert (VertexInput v)
		{
			VertexOutput o = (VertexOutput)0;
			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			o.uv = v.texcoord* _MainTex_ST.xy + _MainTex_ST.zw;
			return o;
		}

		fixed4 frag (VertexOutput i) : COLOR
		{
			fixed4 c;
			c = tex2D(_MainTex, i.uv);
			return c;
		}
		ENDCG 
	}
	
	Pass 
	{
		Stencil
		{
			Ref 0
			Comp equal
			Pass incrWrap
			Fail keep
			ZFail keep
		}
		
		Cull Back
		ZWrite Off	
	
		Blend SrcAlpha OneMinusSrcAlpha
		ColorMask RGB
		
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag	

		#pragma multi_compile _FAKE_SHADOW_ON _FAKE_SHADOW_OFF

		uniform float4 _ShadowPlane;
		uniform float4 _ShadowProjDir;
		uniform half4 _ShadowFadeParams;
		uniform half _ShadowInvLen;

	    struct v2f {
	        float4 pos : SV_POSITION;
			half3 worldPos : TEXCOORD0;
			half3 planePos : TEXCOORD1;
	    };
	    
	    v2f vert (appdata_base v)
		{
			float4 plane = _ShadowPlane;
			float3 projDir = normalize(_ShadowProjDir);
	
			float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
	
			float d1 = dot(plane.xyz, worldPos)-plane.w;
			float d2 = d1 / dot(plane.xyz, projDir);

			float3 planePos = worldPos - d2 * projDir;

			v2f o;
			o.pos = mul(UNITY_MATRIX_VP, float4(planePos, 1));
			//o.worldPos = mul(_Object2World, v.vertex).xyz;
			o.worldPos = mul(unity_ObjectToWorld, float4(0,0,0,1)).xyz;
			o.planePos = planePos;

			return o;
		}


		fixed4 frag (v2f i) : COLOR
		{

		#if _FAKE_SHADOW_OFF
			return float4(0.0, 0.0, 0.0, 0.0);
		#endif

			half3 posToPlane = i.worldPos - i.planePos;
			half dist = sqrt(dot(posToPlane,posToPlane));
			half f = pow(1 - saturate(dist * _ShadowInvLen - _ShadowFadeParams.x), _ShadowFadeParams.y);
			f *= _ShadowFadeParams.z;
			return float4(0, 0, 0, f);
		}

		ENDCG 
	}
	


}




}


