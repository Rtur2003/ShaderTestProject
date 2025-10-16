Shader "URP/Glass"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (0.1, 0.3, 0.8, 0.5)
        _Smoothness("Smoothness", Range(0, 1)) = 0.95
        _RefractionPower("Refraction Power", Range(0, 0.1)) = 0.02
        _FresnelPower("Fresnel Power", Range(0, 10)) = 5.0
        _FresnelColor("Fresnel Color", Color) = (1, 1, 1, 1)
        _ReflectionStrength("Reflection Strength", Range(0, 2)) = 1.0
        _GlassAmount("Glass Amount",Range(0,2))=0
        
        _NormalMap("Normal Map", 2D) = "bump" {}
        _NormalStrength("Normal Strength", Range(0, 2)) = 0.3
    }
    
    SubShader
    {
        Tags 
        { 
            "RenderType" = "Transparent" 
            "Queue" = "Transparent"
            "RenderPipeline" = "UniversalPipeline"
        }
        
        // Depth write for transparency
        Pass
        {
            Name "DepthWrite"
            Tags { "LightMode" = "SRPDefaultUnlit" }
            
            ZWrite On
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
            };

            float _GlassAmount;

            Varyings vert (Attributes input)
            {
                Varyings output;
                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz)*_GlassAmount;
                return output;
            }

            half4 frag (Varyings input) : SV_Target
            {
                return 0;
            }
            ENDHLSL
        }

        // Main glass pass
        Pass
        {
            Name "Glass"
            Tags { "LightMode" = "UniversalForward" }
            
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Off
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 normalWS : TEXCOORD0;
                float3 viewDirWS : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                float4 screenPos : TEXCOORD3;
                float2 uv : TEXCOORD4;
                float3 tangentWS : TEXCOORD5;
                float3 bitangentWS : TEXCOORD6;
            };

            CBUFFER_START(UnityPerMaterial)
            float4 _BaseColor;
            float _Smoothness;
            float _RefractionPower;
            float _FresnelPower;
            float4 _FresnelColor;
            float _ReflectionStrength;
            float _NormalStrength;
            CBUFFER_END

            TEXTURE2D(_NormalMap);
            SAMPLER(sampler_NormalMap);

            // Fresnel effect function
            float FresnelEffect(float3 normal, float3 viewDir, float power)
            {
                float fresnel = pow(1.0 - saturate(dot(normal, viewDir)), power);
                return fresnel;
            }

            Varyings vert (Attributes input)
            {
                Varyings output;
                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
                output.worldPos = TransformObjectToWorld(input.positionOS.xyz);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.viewDirWS = GetWorldSpaceNormalizeViewDir(output.worldPos);
                output.screenPos = ComputeScreenPos(output.positionHCS);
                output.uv = input.uv;
                
                // Tangent space calculations
                output.tangentWS = TransformObjectToWorldDir(input.tangentOS.xyz);
                output.bitangentWS = cross(output.normalWS, output.tangentWS) * input.tangentOS.w;
                
                return output;
            }
            
            half4 frag (Varyings input) : SV_Target
            {
                // Normalize vectors
                float3 normalWS = normalize(input.normalWS);
                float3 viewDirWS = normalize(input.viewDirWS);
                float3 tangentWS = normalize(input.tangentWS);
                float3 bitangentWS = normalize(input.bitangentWS);
                
                // NORMAL MAP 
                float3 normalMap = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, input.uv));
                normalMap.xy *= _NormalStrength;
                
                // Tangent to World space
                float3x3 TBN = float3x3(tangentWS, bitangentWS, normalWS);
                float3 detailedNormal = mul(normalMap.xyz, TBN);
                detailedNormal = normalize(detailedNormal);
                
                // REFRACTION - Background distortion
                float2 screenUV = input.screenPos.xy / input.screenPos.w;
                float2 refractOffset = detailedNormal.xz * _RefractionPower;
                float3 refractColor = SampleSceneColor(screenUV + refractOffset);
                
                // REFLECTION - Environment reflection 
                float3 reflectDir = reflect(-viewDirWS, detailedNormal);
                half4 reflectionData = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectDir, (1 - _Smoothness) * 8);
                half3 reflectionColor = DecodeHDREnvironment(reflectionData, unity_SpecCube0_HDR);
                
                // FRESNEL - Edge highlight
                float fresnel = FresnelEffect(detailedNormal, viewDirWS, _FresnelPower);
                float3 fresnelColor = fresnel * _FresnelColor.rgb;
                
                // COMBINE ALL EFFECTS
                half3 finalColor = refractColor; // Base: refracted background
                finalColor = lerp(finalColor, reflectionColor, _Smoothness * _ReflectionStrength); // Add reflection
                finalColor += fresnelColor; // Add fresnel edges
                finalColor *= _BaseColor.rgb; // Tint with base color
                
                // ALPHA - More transparent in center, opaque at edges
                float alpha = _BaseColor.a;
                alpha = lerp(alpha * .3, alpha, fresnel); // Edges more opaque
                
                return half4(finalColor, alpha);
            }
            ENDHLSL
        }
    }
}