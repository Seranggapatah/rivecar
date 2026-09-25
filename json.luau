-- Minimal JSON decoder for glTF / GLB chunk data.
local json = {}

type Parser = {
    text: string,
    i: number,
    n: number,
}

local function peek(p: Parser): string
    if p.i > p.n then
        return ""
    end
    return string.sub(p.text, p.i, p.i)
end

local function skip(p: Parser)
    while p.i <= p.n do
        local c = string.sub(p.text, p.i, p.i)
        if c ~= " " and c ~= "\n" and c ~= "\r" and c ~= "\t" then
            break
        end
        p.i += 1
    end
end

local parseValue: (Parser) -> any

local function parseString(p: Parser): string
    p.i += 1
    local start = p.i
    local chunks: { string } = {}
    while p.i <= p.n do
        local c = string.sub(p.text, p.i, p.i)
        if c == '"' then
            table.insert(chunks, string.sub(p.text, start, p.i - 1))
            p.i += 1
            return table.concat(chunks)
        elseif c == "\\" then
            table.insert(chunks, string.sub(p.text, start, p.i - 1))
            p.i += 1
            local e = string.sub(p.text, p.i, p.i)
            if e == "n" then
                table.insert(chunks, "\n")
            elseif e == "t" then
                table.insert(chunks, "\t")
            elseif e == "r" then
                table.insert(chunks, "\r")
            elseif e == "u" then
                local hex = string.sub(p.text, p.i + 1, p.i + 4)
                local code = tonumber(hex, 16)
                if code == nil then
                    error("bad unicode escape")
                end
                if code < 128 then
                    table.insert(chunks, string.char(code))
                else
                    table.insert(chunks, "?")
                end
                p.i += 4
            else
                table.insert(chunks, e)
            end
            p.i += 1
            start = p.i
        else
            p.i += 1
        end
    end
    error("unterminated string")
end

local function parseNumber(p: Parser): number
    local start = p.i
    if peek(p) == "-" then
        p.i += 1
    end
    while p.i <= p.n do
        local c = string.sub(p.text, p.i, p.i)
        if (c >= "0" and c <= "9") or c == "." or c == "e" or c == "E" or c == "+" or c == "-" then
            p.i += 1
        else
            break
        end
    end
    local n = tonumber(string.sub(p.text, start, p.i - 1))
    if n == nil then
        error("bad number")
    end
    return n
end

local function parseArray(p: Parser): { any }
    p.i += 1
    local arr: { any } = {}
    skip(p)
    if peek(p) == "]" then
        p.i += 1
        return arr
    end
    while true do
        skip(p)
        table.insert(arr, parseValue(p))
        skip(p)
        local c = peek(p)
        if c == "," then
            p.i += 1
        elseif c == "]" then
            p.i += 1
            break
        else
            error("bad array")
        end
    end
    return arr
end

local function parseObject(p: Parser): { [string]: any }
    p.i += 1
    local obj: { [string]: any } = {}
    skip(p)
    if peek(p) == "}" then
        p.i += 1
        return obj
    end
    while true do
        skip(p)
        if peek(p) ~= '"' then
            error("expected string key")
        end
        local key = parseString(p)
        skip(p)
        if peek(p) ~= ":" then
            error("expected colon")
        end
        p.i += 1
        skip(p)
        obj[key] = parseValue(p)
        skip(p)
        local c = peek(p)
        if c == "," then
            p.i += 1
        elseif c == "}" then
            p.i += 1
            break
        else
            error("bad object")
        end
    end
    return obj
end

parseValue = function(p: Parser): any
    skip(p)
    local c = peek(p)
    if c == '"' then
        return parseString(p)
    elseif c == "{" then
        return parseObject(p)
    elseif c == "[" then
        return parseArray(p)
    elseif c == "t" then
        p.i += 4
        return true
    elseif c == "f" then
        p.i += 5
        return false
    elseif c == "n" then
        p.i += 4
        return nil
    else
        return parseNumber(p)
    end
end

function json.parse(text: string): any
    local p: Parser = { text = text, i = 1, n = #text }
    local value = parseValue(p)
    skip(p)
    return value
end

return json
