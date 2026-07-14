--!strict
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local Players           = game:GetService("Players")
local Packages          = ReplicatedStorage:WaitForChild("Packages")
local Knit              = require(Packages:WaitForChild("Knit"))

local CameraController = Knit.CreateController({ Name = "CameraController" })

local camera      = Workspace.CurrentCamera
local _localPlayer = Players.LocalPlayer

-- Camera state
local _yaw:   number  = -45   -- horizontal rotation degrees
local _pitch: number  = -50   -- vertical angle degrees (negative = looking down)
local _dist:  number  = 60    -- distance from focus point (studs)
local _focus: Vector3 = Vector3.new(0, 0, 0)

local MIN_PITCH = -80
local MAX_PITCH = -15
local MIN_DIST  = 15
local MAX_DIST  = 150

local _panning:      boolean  = false
local _lastMousePos: Vector2? = nil

local function updateCamera()
    local yawRad   = math.rad(_yaw)
    local pitchRad = math.rad(_pitch)

    local offset = Vector3.new(
        math.cos(pitchRad) * math.sin(yawRad),
        math.sin(-pitchRad),
        math.cos(pitchRad) * math.cos(yawRad)
    ) * _dist

    local camPos = _focus + offset
    camera.CameraType = Enum.CameraType.Scriptable
    camera.CFrame     = CFrame.lookAt(camPos, _focus)
end

function CameraController:KnitInit() end

function CameraController:KnitStart()
    -- Disable default Roblox camera
    camera.CameraType = Enum.CameraType.Scriptable

    -- Scroll to zoom + middle-mouse movement pan
    UserInputService.InputChanged:Connect(function(input: InputObject)
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            _dist = math.clamp(_dist - input.Position.Z * 5, MIN_DIST, MAX_DIST)
        end

        if _panning and input.UserInputType == Enum.UserInputType.MouseMovement then
            if _lastMousePos then
                local delta = input.Position - Vector3.new(_lastMousePos.X, _lastMousePos.Y, 0)
                local rightVec   = Vector3.new(math.cos(math.rad(_yaw)),  0, -math.sin(math.rad(_yaw)))
                local forwardVec = Vector3.new(math.sin(math.rad(_yaw)),  0,  math.cos(math.rad(_yaw)))
                _focus = _focus - rightVec * delta.X * 0.15 + forwardVec * delta.Y * 0.15
            end
            _lastMousePos = Vector2.new(input.Position.X, input.Position.Y)
        end
    end)

    -- Middle mouse button engages / disengages pan
    UserInputService.InputBegan:Connect(function(input: InputObject)
        if input.UserInputType == Enum.UserInputType.MouseButton3 then
            _panning      = true
            _lastMousePos = nil
        end
    end)

    UserInputService.InputEnded:Connect(function(input: InputObject)
        if input.UserInputType == Enum.UserInputType.MouseButton3 then
            _panning      = false
            _lastMousePos = nil
        end
    end)

    -- WASD / arrow-key pan of focus point + camera update each frame
    RunService.RenderStepped:Connect(function(dt: number)
        local speed      = _dist * 0.5 * dt
        local rightVec   = Vector3.new(math.cos(math.rad(_yaw)), 0, -math.sin(math.rad(_yaw)))
        local forwardVec = Vector3.new(math.sin(math.rad(_yaw)), 0,  math.cos(math.rad(_yaw)))

        if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then
            _focus = _focus + forwardVec * speed
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then
            _focus = _focus - forwardVec * speed
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then
            _focus = _focus - rightVec * speed
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then
            _focus = _focus + rightVec * speed
        end

        updateCamera()
    end)
end

return CameraController
