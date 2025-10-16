Shader "URP/SdfShader"
{
    Properties
    {
        _CircleRadius("Circle Radius", Range(0, 1)) = 0.3
        _EdgeSmoothness("Edge Smoothness", Range(0, 0.1)) = 0.01
        _CircleColor("Circle Color", Color) = (1, 1, 1, 1)
        _BackgroundColor("Background Color", Color) = (0, 0, 0, 1)
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
                float _CircleRadius;
                float _EdgeSmoothness;
                half4 _CircleColor;
                half4 _BackgroundColor;
            CBUFFER_END

            Varyings vert (Attributes input)
            {
                Varyings output;
                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);

                // Convert UV from [0,1] to [-1,1] for SDF
                output.uv = input.uv * 2.0 - 1.0;

                return output;
            }

            half4 frag (Varyings input) : SV_Target
            {
                // Signed Distance Field: circle
                float dist = length(input.uv) - _CircleRadius;

                // Smooth step for anti-aliased edge
                float circle = smoothstep(_EdgeSmoothness, -_EdgeSmoothness, dist);

                // Blend between background and circle color
                half4 color = lerp(_BackgroundColor, _CircleColor, circle);

                return color;
            }
            ENDHLSL
        }
    }

    FallBack "Universal Render Pipeline/Unlit"
}
