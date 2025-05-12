--- 公会战7.0新增龙怒系统的代理组件，用于封装龙怒系统玩法在XGuildWarAgency上的接口
---@class XDragonRageAgencyCom
---@field _OwnerAgency XGuildWarAgency
---@field _OwnerModel XGuildWarModel
local XDragonRageAgencyCom = XClass(nil, 'XDragonRageAgencyCom')

function XDragonRageAgencyCom:Init(ownerAgency, ownerModel)
    self._OwnerAgency = ownerAgency
    self._OwnerModel = ownerModel
end

function XDragonRageAgencyCom:Release()
    self._OwnerAgency = nil
    self._OwnerModel = nil
end

--- 从登录下推数据中找出需要的数据进行缓存
function XDragonRageAgencyCom:UpdateDataFromLoginNotify(data)
    self.HaveMyRoundData = false
    if not XTool.IsTableEmpty(data.ActivityData.RoundData) then
        for i, myRoundData in pairs(data.ActivityData.RoundData) do
            -- 只更新查找当前轮次的数据
            if myRoundData.RoundId == XDataCenter.GuildWarManager.GetCurrentRoundId() then
                -- 3.0改版后 以服务器数据标记为主
                if XDataCenter.GuildManager.GetGuildId() == myRoundData.GuildId
                        and myRoundData.DifficultyId == 0 then
                    return
                end

                self._OwnerModel:GetDragonRageData():UpdateDragonRageData(myRoundData)

                self.HaveMyRoundData = true
            end
        end
    end
end

function XDragonRageAgencyCom:UpdateDragonRageValue(value)
    ---@type XGuildWarDragonRageData
    local dragonRageData = self._OwnerModel:GetDragonRageData()

    dragonRageData:UpdateDragonRageValue(value)
end

function XDragonRageAgencyCom:RefreshDataFromActivityData(activityData)
    if XTool.IsTableEmpty(activityData) then
        return
    end
    
    if not XTool.IsTableEmpty(activityData.RoundData) then
        for i, myRoundData in pairs(activityData.RoundData) do
            -- 只更新查找当前轮次的数据
            if myRoundData.RoundId == XDataCenter.GuildWarManager.GetCurrentRoundId() then
                if XDataCenter.GuildManager.GetGuildId() == myRoundData.GuildId
                        and myRoundData.DifficultyId == 0 then
                    return
                end

                self._OwnerModel:GetDragonRageData():UpdateDragonRageData(myRoundData)
            end
        end
    end
end

function XDragonRageAgencyCom:IsOpenDragonRageSystem()
    return self._OwnerModel:GetDragonRageData():GetIsOpenDragonRage()
end

--- 临时缓存，记录当前登录最新周目action的Id，防止之前的action延时下发导致重复播放
function XDragonRageAgencyCom:SetCurLatestNewGameActionId(actionId)
    self._OwnerModel:GetDragonRageData():SetCurLatestNewGameActionId(actionId)
end

function XDragonRageAgencyCom:GetCurLatestNewGameActionId()
    return self._OwnerModel:GetDragonRageData():GetCurLatestNewGameActionId()
end

--- 临时缓存，标记存在周目行为等待播放，用于Boss详情界面踢出
function XDragonRageAgencyCom:SetIsNewGameThroughActionWaitToPlay(isHave)
    self._OwnerModel:GetDragonRageData():SetIsNewGameThroughActionWaitToPlay(isHave)
end

function XDragonRageAgencyCom:GetIsNewGameThroughActionWaitToPlay()
    return self._OwnerModel:GetDragonRageData():GetIsNewGameThroughActionWaitToPlay()
end

--- 当前龙怒等级
function XDragonRageAgencyCom:GetDragonRageLevel()
    return self._OwnerModel:GetDragonRageData():GetDragonRageLevel()
end

return XDragonRageAgencyCom