local XEquipTarget = require("XEntity/XEquipGuide/XEquipTarget")

local Default = {
    _Id = 0,    --CharacterId
    _EquipTarget = nil,     --当前的装备目标
    _EquipTargetDict = {},  --装备目标列表
}

local XEquipGuide = XClass(XDataEntityBase, "XEquipGuide")

function XEquipGuide:Ctor(characterId)
    self:Init(Default, characterId)
end

function XEquipGuide:InitData(characterId)
    self:SetProperty("_Id", characterId)
end

function XEquipGuide:GetTarget(targetId)
    if not XTool.IsNumberValid(targetId) then
        return
    end
    return self._EquipTargetDict[targetId]
end

function XEquipGuide:SetTarget(targetId, list)
    if self._EquipTarget 
            and self._EquipTarget:GetProperty("_Id") == targetId then
        self._EquipTarget:UpdatePutOnPosList(list)
        return
    end
    local target = self._EquipTargetDict[targetId]
    if target then
        self:SetProperty("_EquipTarget", target)
        target:UpdatePutOnPosList(list)
    end
end

function XEquipGuide:ClearTarget()
    if not self._EquipTarget then
        return
    end
    self._EquipTarget:Clear()
    self._EquipTarget = nil
end

function XEquipGuide:InsertTarget(targetId)
    local target = XEquipTarget.New(targetId)
    target:SetProperty("_CharacterId", self._Id)
    self._EquipTargetDict[targetId] = target
end

function XEquipGuide:UpdateTarget(targetId, data)
    local target = self._EquipTargetDict[targetId]
    if not target then
        return
    end
    
    target:UpdateData(data)
end

function XEquipGuide:GetTargetList()
    local list = {}
    for _, target in pairs(self._EquipTargetDict) do
        if not target:GetProperty("_Hidden") then
            table.insert(list, target)
        end
    end
    
    table.sort(list, function(a, b) 
        return a:GetProperty("_Id") < b:GetProperty("_Id")
    end)
    return list
end


function XEquipGuide:IsEquipTarget(targetId)
    if not self._EquipTarget then
        return false
    end
    return self._EquipTarget:GetProperty("_Id") == targetId
end

function XEquipGuide:GetWeaponCount()
    local count = 0
    for _, target in pairs(self._EquipTargetDict) do
        local recommendId = target:GetProperty("_RecommendId")
        if XTool.IsNumberValid(recommendId) then
            local template = XMVCA.XEquip:GetCharDetailEquipTemplate(recommendId)
            local tId = template.EquipRecomend
            local star = XMVCA.XEquip:GetEquipStar(tId)
            if star >= XEnumConst.EQUIP.MAX_STAR_COUNT then
                local equipIds = XMVCA.XEquip:GetEnableEquipIdsByTemplateId(tId)
                count = count + #equipIds
            end
        end
    end
    return count
end

return XEquipGuide