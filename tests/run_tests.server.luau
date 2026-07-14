--!strict
-- Test entry point. Run this script in a test.project.json Studio session
-- to execute all TestEZ specs under ReplicatedStorage.Shared.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DevPackages = ReplicatedStorage:WaitForChild("DevPackages")
local TestEZ = require(DevPackages:WaitForChild("TestEZ"))

local results = TestEZ.TestBootstrap:run({
    ReplicatedStorage.Shared,   -- runs any *.spec.luau under Shared
    ServerScriptService.Tests,  -- runs any *.spec.luau under Tests
})

if results.failureCount > 0 then
    error(string.format("[TestEZ] %d test(s) FAILED", results.failureCount))
else
    print(string.format("[TestEZ] All %d test(s) PASSED", results.successCount))
end
