Shader "URP/Triplanar"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Tiling ("Tiling", Float) = 1.0
        _BlendSharpness ("Blend Sharpness", Range(1, 10)) = 4.0
        _OcclusionMap ("Occlusion", 2D) = "white" {}
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
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionOS : TEXCOORD0;
                float3 normalOS : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            TEXTURE2D(_OcclusionMap);
            SAMPLER(sampler_OcclusionMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _OcclusionMap_ST;
                float _Tiling;
                float _BlendSharpness;
            CBUFFER_END

            Varyings vert (Attributes input)
            {
                Varyings output;
                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
                output.positionOS = input.positionOS.xyz;
                output.normalOS = input.normalOS;
                output.uv = TRANSFORM_TEX(input.uv, _OcclusionMap);
                return output;
            }

            half4 frag (Varyings input) : SV_Target
            {
                // Triplanar coordinates
                float3 coord = input.positionOS * _Tiling;

                // Sample texture for each axis
                half4 texX = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, coord.yz);
                half4 texY = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, coord.xz);
                half4 texZ = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, coord.xy);

                // Calculate blend weights using absolute normal values
                float3 blend = pow(abs(input.normalOS), _BlendSharpness);
                // Normalize weights so they sum to 1
                blend = blend / (blend.x + blend.y + blend.z);

                // Blend the three projections
                half4 triplanarColor = texX * blend.x + texY * blend.y + texZ * blend.z;

                // Apply occlusion map
                half4 occlusion = SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, input.uv);
                triplanarColor *= occlusion;

                return triplanarColor;
            }
            ENDHLSL
        }
    }

    FallBack "Universal Render Pipeline/Unlit"
}
