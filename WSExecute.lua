local function Init()
    local Services = setmetatable({}, {
        __index = function(_, Key)
            return game:GetService(Key)
        end
    })

    local Client = Services.Players.LocalPlayer
    local SMethod = WebSocket and WebSocket.connect

    if not SMethod then
        return false, "WebSocket not supported by executor"
    end

    local Success, WebSocket = pcall(SMethod, "ws://localhost:9000/")
    if not Success or not WebSocket then
        return false, "Failed to connect to WebSocket server"
    end

    local Closed = false

    WebSocket:Send(Services.HttpService:JSONEncode({
        Method = "Authorization",
        Name = Client.Name
    }))

    WebSocket.OnMessage:Connect(function(Unparsed)
        local Parsed
        local ok = pcall(function()
            Parsed = Services.HttpService:JSONDecode(Unparsed)
        end)
        if not ok then return end

        if Parsed.Method == "Execute" then
            local func, loadErr = loadstring(Parsed.Data)
            if not func then
                WebSocket:Send(Services.HttpService:JSONEncode({
                    Method = "Error",
                    Message = loadErr
                }))
                return
            end
            local execOk, execErr = pcall(func)
            if not execOk then
                WebSocket:Send(Services.HttpService:JSONEncode({
                    Method = "Error",
                    Message = execErr
                }))
            end
        end
    end)

    WebSocket.OnClose:Connect(function()
        Closed = true
    end)

    task.spawn(function()
        repeat task.wait() until Closed
    end)

    return true, "Connected to WebSocket and ready"
end

return {
    Init = Init
}
