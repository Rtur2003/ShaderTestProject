Shader "URP/CheckerShader"
{
    Properties
    {
        _Density ("Density", Range(2, 64)) = 30
        _SpeedX ("Speed X", Range(-20, 20)) = 0
        _SpeedY ("Speed Y", Range(-20, 20)) = 0
        _Color1 ("Color 1", Color) = (0, 0, 0, 1)
        _Color2 ("Color 2", Color) = (1, 1, 1, 1)
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Geometry"
        }

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
                float _Density;
                float _SpeedX;
                float _SpeedY;
                half4 _Color1;
                half4 _Color2;
            CBUFFER_END

            Varyings vert (Attributes input)
            {
                Varyings output;
                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);

                // Apply density and animated offset
                output.uv = input.uv * _Density;
                output.uv.x += _Time.y * _SpeedX;
                output.uv.y += _Time.y * _SpeedY;

                return output;
            }

            half4 frag (Varyings input) : SV_Target
            {
                // Calculate checker pattern
                float2 c = floor(input.uv) / 2.0;
                float checker = frac(c.x + c.y) * 2.0;

                // Lerp between two colors
                return lerp(_Color1, _Color2, checker);
            }
            ENDHLSL
        }
    }

    FallBack "Universal Render Pipeline/Unlit"
}
