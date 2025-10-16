Shader "Unlit/Deneme"
{
    Properties
    {
        _Color ("Color",Color)= (0,0,0,0)
        _Speed ("Speed", Range(0,5))=1
        _Height ("Height",Range(0,1))=.25
        _Frequency("Frequency",Range(0,10))=3
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            fixed4 _Color;
            float _Speed;
            float _Height;
            float _Frequency;
            
            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                float wave=sin(v.vertex.x*_Frequency+_Time.y*_Speed)*_Height;
                v.vertex.y+=wave;
                o.pos=UnityObjectToClipPos(v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return _Color;
            }
            ENDCG
        }
    }
}
