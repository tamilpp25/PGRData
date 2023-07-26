---@class XGDComponentManager
local XGDComponentManager = XClass(nil, "XGDComponentManager")

function XGDComponentManager:Ctor()
    -- 组件 XGDComponet
    self.Componets = {}
    self.ComponetDic = {}
end

function XGDComponentManager:AddComponent(compoent, pos)
    if pos == nil then 
        table.insert(self.Componets, compoent)
    else
        table.insert(self.Componets, pos, compoent)
    end
    self.ComponetDic[compoent.__cname] = compoent
    compoent:Init()
end

function XGDComponentManager:GetComponent(className)
    return self.ComponetDic[className]
end

function XGDComponentManager:GetComponents()
    return self.Componets
end

function XGDComponentManager:Update(dt)
    for _, component in ipairs(self.Componets) do
        if component.Update then
            if component:CheckCanUpdate(dt) then
                component:Update(dt)
            end
        end
    end
end

function XGDComponentManager:Dispose()
    for _, com in ipairs(self.Componets) do
        com:Dispose()
    end
    self.Componets = nil
    self.ComponetDic = nil
    self.Componets = {}
    self.ComponetDic = {}
end

return XGDComponentManager