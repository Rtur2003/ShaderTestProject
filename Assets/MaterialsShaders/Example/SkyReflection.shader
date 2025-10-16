/*
 * SkyReflection Shader
 *
 * Purpose: Creates realistic reflections from environment cubemap
 * Use Case: Metallic/reflective surfaces, chrome effects
 * Performance: Low (cubemap sampling)
 *
 * Features:
 * - Environment reflection probe sampling
 * - HDR decoding for accurate lighting
 * - Adjustable reflection strength
 * - Perfect for mirror-like surfaces
 */

Shader "URP/SkyReflection"
{
    Properties
    {
        _ReflectionStrength("Reflection Strength", Range(0, 2)) = 1.5
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
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 worldReflection : TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
                float _ReflectionStrength;
            CBUFFER_END

            Varyings vert (Attributes input)
            {
                Varyings output;

                // Transform to clip space
                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);

                // Calculate world space position and normal
                float3 worldPos = TransformObjectToWorld(input.positionOS.xyz);
                float3 worldNormal = TransformObjectToWorldNormal(input.normalOS);

                // Calculate view direction
                float3 worldViewDir = normalize(GetWorldSpaceViewDir(worldPos));

                // Calculate reflection vector
                output.worldReflection = reflect(-worldViewDir, worldNormal);

                return output;
            }

            half4 frag (Varyings input) : SV_Target
            {
                // Sample reflection probe (environment cubemap)
                half4 skyData = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, input.worldReflection, 0);

                // Decode HDR
                half3 skyColor = DecodeHDREnvironment(skyData, unity_SpecCube0_HDR);

                // Apply reflection strength
                skyColor *= _ReflectionStrength;

                return half4(skyColor, 1.0);
            }
            ENDHLSL
        }
    }

    FallBack "Universal Render Pipeline/Unlit"
}
