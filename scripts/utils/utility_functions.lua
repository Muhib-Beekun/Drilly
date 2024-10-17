-- scripts/utils/utility_functions.lua

local utility_functions = {}

function utility_functions.table_size(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

-- Utility: Format numbers with commas
function utility_functions.format_number_with_commas(number)
    -- Convert the number to string to analyze its decimal part
    local formatted = tostring(number)

    -- Separate integer and decimal parts (if any)
    local integer_part, decimal_part = string.match(formatted, "(%-?%d+)(%.%d+)")

    -- Check if the number has a decimal part
    if decimal_part then
        -- Check the length of the decimal part (excluding the decimal point)
        local decimal_digits = string.sub(decimal_part, 2)
        if #decimal_digits > 4 then
            -- Round the number to 4 decimal places
            formatted = string.format("%.4f", number)
            -- Update the integer and decimal parts after rounding
            integer_part, decimal_part = string.match(formatted, "(%-?%d+)(%.%d+)")
        end
    else
        -- No decimal part, use the integer part as is
        integer_part = formatted
        decimal_part = ""
    end

    -- Insert commas into the integer part
    local k
    local formatted_int = integer_part
    while true do
        formatted_int, k = string.gsub(formatted_int, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end

    -- Reconstruct the formatted number
    return formatted_int .. (decimal_part or "")
end

return utility_functions
