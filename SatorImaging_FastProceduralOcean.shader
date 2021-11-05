Shader "Sator Imaging/Fast Procedural Ocean"
{
    Properties
    {
        [Header(GPU Instancing cannot be used due to Phong Tessellation)]
        [Space]
        _Phong("Phong Tessellation Strength", Range(0, 1)) = 0.5
        _EdgeLength("Tessellation Edge Length", Range(2.5, 100)) = 100

        [Space]
        [IntRange] _VertexIterations ("Vertex Iterations", Range(1, 64)) = 10
        [IntRange] _NormalIterations ("Normal Iterations", Range(1, 64)) = 30
        // vertex and normal doesn't match.
        //[Toggle] _TangentSpace ("Tangent Space Deformation", Float) = 0

        [Space]
        _WaveDensity ("Wave Density", Range(1, 10)) = 4
        _WaveHeight ("Wave Height", Range(0, 1)) = 0.5
        _WaveSharpness ("Wave Peak Strength", Range(0.01, 0.4)) = 0.2//0.048

        [Space]
        _WaveNormalStrength ("Wave Normal Strength", Range(0,2)) = 1

        [Space]
        _WaveSpeed ("Wave Speed", Range(0, 50)) = 10
        _WaveMovement ("Wave Movement", Vector) = (0, 0, 0, 0)

        _Color ("Color", Color) = (0.2216981, 0.6714061, 1, 1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0, 1)) = 0.5
        _Metallic ("Metallic", Range(0, 1)) = 0.0

    }
    SubShader
    {
        Tags { "Queue" = "Geometry" "RenderType" = "Opaque" }
        Cull Back


        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard vertex:vert fullforwardshadows addshadow tessellate:tessEdge tessphong:_Phong /////alpha:blend keepalpha

        #pragma multi_compile_local  _  _TANGENTSPACE_ON

        #include "Tessellation.cginc"
        #include "SatorImaging_FastProceduralOcean.cginc"

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0



        fixed4 _Color;
        sampler2D _MainTex;
        half _Glossiness;
        half _Metallic;

        int _VertexIterations;
        int _NormalIterations;

        half _WaveDensity;
        half _WaveHeight;
        half _WaveSharpness;
        half _WaveNormalStrength;
        half _WaveSpeed;
        half3 _WaveMovement;





        float _Phong;
        float _EdgeLength;

        float4 tessEdge(appdata_full v0, appdata_full v1, appdata_full v2)
        {
            return UnityEdgeLengthBasedTess(v0.vertex, v1.vertex, v2.vertex, _EdgeLength);
        }



        void vert (inout appdata_full v) {
            #if _TANGENTSPACE_ON
                v.vertex.xyz += v.normal * getwaves(v.texcoord.xy*10 + _WaveMovement.xz*_Time, _VertexIterations, _Time * _WaveSpeed, _WaveDensity, _WaveSharpness) * _WaveHeight;
            #else
                v.vertex.y += getwaves(v.vertex.xz + _WaveMovement.xz*_Time, _VertexIterations, _Time * _WaveSpeed, _WaveDensity, _WaveSharpness) * _WaveHeight;
            #endif
        }




        struct Input
        {
            float2 uv_MainTex;
            float3 worldPos;
            INTERNAL_DATA
            //float3 worldRefl;
            float3 worldNormal;
        };


        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            #if _TANGENTSPACE_ON
                half3x3 w2t = half3x3(
                    WorldNormalVector(IN, float3(1,0,0)),
                    WorldNormalVector(IN, float3(0,1,0)),
                    WorldNormalVector(IN, float3(0,0,1))
                );
                o.Normal = lerp(o.Normal, normalize(mul( w2t, half4(
                                normal(IN.uv_MainTex.xy*10 + _WaveMovement.xz*_Time, 0.001, 1, _Time * _WaveSpeed, _NormalIterations, _WaveDensity, _WaveSharpness), 1
                            ))), _WaveNormalStrength);
            #else
                half3x3 w2t = half3x3(
                    WorldNormalVector(IN, float3(1,0,0)),
                    WorldNormalVector(IN, float3(0,1,0)),
                    WorldNormalVector(IN, float3(0,0,1))
                );
                o.Normal = lerp(o.Normal, normalize(mul( w2t, half4(
                                normal(IN.worldPos.xz + _WaveMovement.xz*_Time, 0.001, 1, _Time * _WaveSpeed, _NormalIterations, _WaveDensity, _WaveSharpness), 1
                            ))), _WaveNormalStrength);
            #endif

            // final touches
            o.Albedo = _Color * tex2D(_MainTex, IN.uv_MainTex);
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
