local function Init(ip: string, port: string)
    local function decompile(script)
        local success, response = pcall(function()
            return request({
                Url = "http://" .. ip .. ":" .. port .. "/decompile",
                Body = base64.encode(getscriptbytecode(script)),
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "text/plain"
                },
            })
        end)

        if not success or not response or not response.Body then
            return nil, "Failed to contact decompiler server"
        end

        return response.Body
    end

    local testScript = Instance.new("LocalScript")
    testScript.Source = "-- test"

    local testResult, err = decompile(testScript)
    testScript:Destroy()

    if not testResult then
        return false, "Init failed: " .. (err or "Unknown error")
    end

    getgenv().decompile = decompile
    return true, "Decompile function initialized successfully"
end

return {
    Init = Init
}
