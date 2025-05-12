---@class XGoldenMinerComponentDirectionPoint:XActivityGameComponent
---@field _OwnControl XEntity
---@field _ParentEntity XGoldenMinerEntityStone
local XGoldenMinerComponentDirectionPoint = XClass(XEntity, "XGoldenMinerComponentDirectionPoint")

--region Override
function XGoldenMinerComponentDirectionPoint:OnInit(stoneId)
    -- Static Value
    self._Id = stoneId
    ---@type UnityEngine.Transform
    self.AngleTransform = false
    ---@type UnityEngine.UI.Image
    self.FillImage = false
    self.AngleList = {}
    self.AngleTimeList = {}
    -- Dynamic Value
    self.CurAngleIndex = 0
    self.CurTime = 0
    ---@type XLuaVector3
    self.CurAngleVector = XLuaVector3.New()
end

function XGoldenMinerComponentDirectionPoint:OnRelease()
    self.AngleTransform = nil
    self.FillImage = nil
end
--endregion

--region Getter
function XGoldenMinerComponentDirectionPoint:GetCurAngle()
    return self.AngleList[self.CurAngleIndex]
end
--endregion

--region Setter
function XGoldenMinerComponentDirectionPoint:SetCurAngle()
    self.CurAngleVector:Update(nil, nil, self:GetCurAngle())
    self.AngleTransform.localEulerAngles = self.CurAngleVector
end
--endregion

--region Control
function XGoldenMinerComponentDirectionPoint:InitAlive()
    self:Update(0)
end

function XGoldenMinerComponentDirectionPoint:Update(deltaTime)
    self.CurTime = self.CurTime - deltaTime
    local angleListCount = #self.AngleList
    if self.CurTime <= 0 and angleListCount > 1 then
        local index = self.CurAngleIndex
        index = index + 1
        if angleListCount < index then
            index = 1
        end
        self.CurAngleIndex = index
        self.CurTime = self.AngleTimeList[index]
        XMVCA.XGoldenMiner:DebugLog("转向点转向:角度:", self.AngleList[index]
                , "持续时间:", self.AngleTimeList[index]
                , ",StoneId:", self._Id)
    end
    -- 更新进度
    if self.FillImage then
        if angleListCount > 1 then
            local timeLimit = self.AngleTimeList[self.CurAngleIndex]
            self.FillImage.fillAmount = 1 - self.CurTime / timeLimit
        else
            self.FillImage.fillAmount = 1
        end
    end
    -- 刷新角度
    if self.CurAngleVector.z ~= self.AngleList[self.CurAngleIndex] then
        self:SetCurAngle()
    end
end
--endregion

return XGoldenMinerComponentDirectionPoint