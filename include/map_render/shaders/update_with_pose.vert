/*
 * This file is part of ElasticFusion.
 *
 * Copyright (C) 2015 Imperial College London
 *
 * The use of the code within this file and all code within files that
 * make up the software that is ElasticFusion is permitted for
 * non-commercial purposes only.  The full terms and conditions that
 * apply to the code within this file are detailed within the LICENSE.txt
 * file and at <http://www.imperial.ac.uk/dyson-robotics-lab/downloads/elastic-fusion/elastic-fusion-license/>
 * unless explicitly stated.  By downloading this file you agree to
 * comply with these terms.
 *
 * If you wish to use any of this code for commercial purposes then
 * please email researchcontracts.engineering@imperial.ac.uk.
 *
 */

#version 330 core
#include "color.glsl"

layout (location = 0) in vec4 vPosition;
layout (location = 1) in vec4 vColor;
layout (location = 2) in vec4 vNormRad;

out vec4 vPosition0;
out vec4 vColor0;
out vec4 vNormRad0;
uniform float texDim;
// uniform int time;
uniform mat4 pose_inv;

uniform sampler2D vertSamp;
uniform sampler2D colorSamp;
uniform sampler2D normSamp;

void main()
{
    int intY = gl_VertexID / int(texDim);
    int intX = gl_VertexID - (intY * int(texDim));

    float halfPixel = 0.5 * (1.0f / texDim);
    float y = (float(intY) / texDim) + halfPixel;
    float x = (float(intX) / texDim) + halfPixel;

    vec4 newColor = textureLod(colorSamp, vec2(x, y), 0);

    //Do averaging here //We found a point to merge with
    if(newColor.w == -1)
    {
        vec4 newPos = textureLod(vertSamp, vec2(x, y), 0);
        vec4 newNorm = textureLod(normSamp, vec2(x, y), 0);

        float c_k = vPosition.w;
        vec3 v_k = vPosition.xyz;

//        float a = newPos.w;
        vec4 localPosition = pose_inv * vec4(vPosition.xyz, 1.0);
        float a = 1 / length(localPosition.xyz) * length(localPosition.xyz); // / length(newPos.xyz) * length(newPos.xyz);
        vec3 v_g = newPos.xyz;

        if(/*newNorm.w < (1.0 + 0.5) * vNormRad.w*/ true)
        {
	        // vPosition0 = vec4(((c_k * v_k) + (a * v_g)) / (c_k + a), c_k + a);
             vPosition0.xyz = vPosition.xyz;
             vPosition0.w = c_k + a;

	         vec3 oldCol = decodeColor(vColor.x);
	         vec3 newCol = decodeColor(newColor.x);

             vec3 avgColor = ((c_k * oldCol.xyz) + (a * newCol.xyz)) / (c_k + a);
//             avgColor = newCol.xyz;
          //
	        // vColor0 = vec4(encodeColor(avgColor), vColor.y, vColor.z, time);
          //
	        // vNormRad0 = ((c_k * vNormRad) + (a * newNorm)) / (c_k + a);
          //
	        // vNormRad0.xyz = normalize(vNormRad0.xyz);

            if (/*true ||*/ vColor.y == -1) {

                vColor0.y = 1;
                // WARNING: temporal use for intensity
                vColor0.w = vColor.w;

                vColor0 = vec4(newColor.x, 1, vColor.z, vColor.w);

                // FIXME: why another if not work???

            //            vColor0 = vec4(ec, 1, vColor.z, vColor.w);
            } /*else {
            vColor0.x = newColor.x;
            vColor0.w = vColor.w;
            }*/
            vColor0 = vec4(encodeColor(avgColor), 1, vColor.z, vColor.w);
            vPosition0.xyz = vPosition.xyz;
            vPosition0.w = c_k + a;
            vNormRad0 = vNormRad;
        }
        else
        {
            vPosition0 = vPosition;
            // TODO: update color
            vColor0 = vColor;
            vNormRad0 = vNormRad;

            vPosition0.w = c_k + a;
            // vColor0.w = time;
        }
    }
    else
    {
        //This point isn't being updated, so just transfer it
	    vPosition0 = vPosition;
	    vColor0 = vColor;
	    vNormRad0 = vNormRad;
    }
}
