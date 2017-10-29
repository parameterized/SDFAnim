
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
	float t = 0.1;
	float tmax = 20.0;
	float m = -1.0;
	for (int i=0; i < 64; i++) {
		float precis = 0.0005*t;
		vec2 res = map(ro + rd*t);
		t += res.x;
		m = res.y;
		if (res.x < precis || t > tmax) { break; }
	}
	if(t > tmax) { m = 0.0; }
	return vec2(t, m);
}

vec3 render(vec3 ro, vec3 rd)
{
	vec2 res = castRay(ro, rd);
	float t = res.x;
	float m = res.y;
	//return vec3(mod(m/(256.0*256.0), 256.0)/255.0, mod(floor(m/256.0), 256.0)/255.0, m/255.0);
	if (m >= 255.0) {
		return vec3(0.0);
	} else {
		return vec3(m/255.0);
	}
}
