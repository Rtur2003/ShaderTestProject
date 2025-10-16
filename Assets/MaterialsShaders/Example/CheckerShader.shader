Shader "Unlit/CheckerShader"
{
    Properties
    {
        _Density ("Density",Range(2,64))=30
        _SpeedX ("Speed_X", Range(-20,20))=0
        _SpeedY ("Speed_Y", Range(-20,20))=0
        _Color1 ("Color_1", Color)=(0,0,0,0)
        _Color2 ("Color_2", Color)=(1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            float _Density;
            float _SpeedX;
            float _SpeedY;
            float4 _Color1;
            float4 _Color2;

            v2f vert (float4 pos : POSITION, float2 uv : TEXCOORD0)
            {
                v2f o;
               o.vertex=UnityObjectToClipPos(pos);
                o.uv=uv*_Density;
                o.uv.x+=_Time.y*_SpeedX;
                o.uv.y+=_Time.y*_SpeedY;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
               float2 c=i.uv;
                c=floor(c)/2;

                //For checker
                float checker=frac(c.x+c.y)*2;

                //For gradient
                float gradient=frac(i.uv.x);
                
                return lerp(_Color1,_Color2,checker);
            }
            ENDHLSL
        }
    }
}
