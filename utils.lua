
function isInt(x)
	return x == math.floor(x)
end

function glslVal(x)
	return (type(x) == 'number' and (x .. (isInt(x) and '.0' or '')) or x)
end

function vecStr(t)
	s = 'vec' .. #t .. '('
	for i, v in pairs(t) do
		if not (i == 1) then
			s = s .. ', '
		end
		s = s .. glslVal(v)
	end
	s = s .. ')'
	return s
end
