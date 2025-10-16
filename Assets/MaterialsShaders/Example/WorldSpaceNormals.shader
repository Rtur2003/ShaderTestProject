/*
 * WorldSpaceNormals Shader
 *
 * Purpose: Visualizes world-space normals as RGB colors
 * Use Case: Debugging normal directions, normal map validation
 * Performance: Very Low (single pass, no textures)
 *
 * Features:
 * - Displays normals in world space
 * - Red = X axis, Green = Y axis, Blue = Z axis
 * - Simple visualization for debugging
 */

Shader "URP/WorldSpaceNormals"
{
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
                float3 normalWS : TEXCOORD0;
            };

            Varyings vert (Attributes input)
            {
                Varyings output;
                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                return output;
            }

            half4 frag (Varyings input) : SV_Target
            {
                // Normalize world space normal
                half3 normalWS = normalize(input.normalWS);

                // Convert from [-1,1] to [0,1] for visualization
                half3 color = normalWS * 0.5 + 0.5;

                return half4(color, 1.0);
            }
            ENDHLSL
        }
    }

    FallBack "Universal Render Pipeline/Unlit"
}
