Shader "Lit/SimpleDiffuse"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (1,1,1,1)
    }
    
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        
        Pass
        {
            Tags {"LightMode"="UniversalForward"}
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

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
                // Basic lighting URP style
                Light mainLight = GetMainLight();
                half3 lightColor = mainLight.color;
                half3 lightDir = normalize(mainLight.direction);

                // Lambert diffuse lighting (N dot L)
                half NdotL = max(0, dot(normalize(input.normalWS), lightDir));
                half3 lighting = NdotL * lightColor;

                // Add ambient light to avoid pure black in shadows
                half3 ambient = half3(0.1, 0.1, 0.1);
                lighting += ambient;

                return half4(lighting, 1);
            }
            ENDHLSL
        }
    }
}