local function Init()
    local Services = setmetatable({}, {
        __index = function(_, Key)
            return game:GetService(Key)
        end
    })
    local Client = Services.Players.LocalPlayer
    local SMethod = WebSocket and WebSocket.connect

    if not SMethod then
        return Client:Kick("Executor is too shitty.")
    end

    local function Main()
        local Success, WebSocket = pcall(SMethod, "ws://localhost:9000/")
        if not Success or not WebSocket then
            return
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
            if not ok then
                return
            end

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

        repeat task.wait() until Closed
    end

    task.spawn(function()
        while true do
            local Success = pcall(Main)
            if not Success then
                task.wait(2)
            end
        end
    end)
end

return Init