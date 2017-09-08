# Copied from Fabian's old implementation
module MoodleTools

push!(LOAD_PATH, dirname(@__FILE__))
push!(LOAD_PATH, dirname(dirname(@__FILE__)))

using MoodleQuiz

export VectorEmbeddedAnswer

function VectorEmbeddedAnswer{S<:AbstractString}( values::AbstractArray; labels::AbstractArray{S} = [], InputSize = 0, name="")
	n = length(values);
	m = isempty(labels) ? 1 : 2;
	noBorderStyle = "border: 0px;"
	innerColStyle = "style=\"  text-align:center; padding:0; border:0px;  border-right: 1px solid black; \"";
	outerColStyle = "style=\"  text-align:center; padding:0; $(noBorderStyle)\"";
	bracketStyle = "style=\"line-height:100%; font-size:4em; vertical-align:top; height:100%; padding:0; $(noBorderStyle)\""
	trStyle = "style=\"padding: 0 0 0 0; vertical-align:middle;\""
	res = "<table style=\"width:auto; vertical-align:middle; display:inline-block; padding:1em 0 1em 0; $(noBorderStyle)\">\n"
	if !isempty(labels)
		res  *= "<tr $trStyle><td $bracketStyle rowspan=\"$m\">(</td>\n"

		for i = 1:n
			colStyle = (i < n) ? innerColStyle : outerColStyle;
			res  *= "<td $colStyle>\\($(labels[i])\\)</td>\n"
		end
		res  *= "<td $bracketStyle rowspan=\"$m\">)</td></tr>\n";
	end
	res  *= "<tr $trStyle>\n"
	if m == 1
		res = string(res,"<td $bracketStyle rowspan=\"$m\">(</td>")
	end
	for i = 1:n
		colStyle = (i < n) ? innerColStyle : outerColStyle;
		res  *= "<td $colStyle>$(NumericalEmbeddedAnswer(values[i];InputSize=InputSize))</td>\n"
	end
	if m==1
		res = string(res,"<td $bracketStyle rowspan=\"$m\">)</td>")
	end
	res  *= "</tr>\n";

	res = string(res,"</table>\n")
	# add "Name = " infront of the matrix
	if name != ""
		res = string("<span style=\"white-space: nowrap; vertical-align:middle\">\$",name,"\$ = ",res,"</span>")
	end
	return res

end

end
