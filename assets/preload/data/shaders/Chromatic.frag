#pragma header
/*
https://www.shadertoy.com/view/wtt3z2
*/

uniform float aberration = 0.0;
uniform float effectTime = 0.0;

vec3 tex2D(sampler2D _tex,vec2 _p)
{
    vec3 col=texture(_tex,_p).xyz;
    if(.5<abs(_p.x-.5)){
        col=vec3(.1);
    }
    return col;
}

void main() {
    vec2 uv = openfl_TextureCoordv; //openfl_TextureCoordv.xy*2. / openfl_TextureSize.xy-vec2(1.);
    vec2 ndcPos = uv * 2.0 - 1.0;
    float aspect = openfl_TextureSize.x / openfl_TextureSize.y;
    
    //float u_angle = -2.4;
    
    float u_angle = -2.4 * sin(effectTime * 2.0);
    
    float eye_angle = abs(u_angle);
    float half_angle = eye_angle/2.0;
    float half_dist = tan(half_angle);

    vec2  vp_scale = vec2(aspect, 1.0);
    vec2  P = ndcPos * vp_scale; 
    
    float vp_dia = length(vp_scale);
    vec2  rel_P = normalize(P) / normalize(vp_scale);

    vec2 pos_prj = ndcPos;

    float beta = abs(atan((length(P) / vp_dia) * half_dist) * -abs(cos(effectTime - 0.25 + 0.5)));
    pos_prj = rel_P * beta / half_angle;

    vec2 uv_prj = (pos_prj * 0.5 + 0.5);

    vec2 trueAberration = aberration * pow((uv_prj.st - 0.5), vec2(3.0, 3.0));
    // vec4 texColor = tex2D(bitmap, uv_prj.st);
	gl_FragColor = vec4(
        texture(bitmap, uv_prj.st + trueAberration).r, 
        texture(bitmap, uv_prj.st).g, 
        texture(bitmap, uv_prj.st - trueAberration).b, 
        1.0
    );
}