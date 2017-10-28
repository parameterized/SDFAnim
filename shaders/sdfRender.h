
mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

vec2 castRay(vec3 ro, vec3 rd)
{
	float t = 0.0;
	float tmax = 20.0;
	float m = 0.0;
	for (int i=0; i < 64; i++) {
		float precis = 0.0005*t;
		vec2 res = map(ro + rd*t);
		if (res.x < precis || t > tmax) { break; }
		t += res.x;
		m = res.y;
	}
	if(t > tmax) { m = -1.0; }
	return vec2(t, m);
}

vec3 calcNormal( in vec3 pos )
{
    vec2 e = vec2(1.0,-1.0)*0.5773*0.0005;
    return normalize( e.xyy*map( pos + e.xyy ).x +
					  e.yyx*map( pos + e.yyx ).x +
					  e.yxy*map( pos + e.yxy ).x +
					  e.xxx*map( pos + e.xxx ).x );
}

vec3 render(vec3 ro, vec3 rd)
{
	vec3 col = vec3(0.7, 0.9, 1.0) + rd.y*0.8;
	vec2 res = castRay(ro, rd);
	float t = res.x;
	float m = res.y;
	vec3 pos = ro + rd*t;
	vec3 nor = calcNormal(pos);
	vec3 lig = normalize(vec3(-0.4, 0.7, -0.6));
	float dif = clamp(dot(nor, lig), 0.0, 1.0);
	if (m == 0.0) {
		float f = mod(floor(5.0*pos.z) + floor(5.0*pos.x), 2.0);
        col = 0.3 + 0.1*f*vec3(1.0);
	} else if (m == 1.0) {
		col *= dif*0.8 + 0.2;
	}
	col = mix( col, vec3(0.8,0.9,1.0), 1.0-exp( -0.0002*t*t*t ) );
	return col;
}
