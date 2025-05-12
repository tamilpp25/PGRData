--- 莉莉丝抽卡动画
---@class XUiLilithGachaShow: XUiGachaCanLiverDrawShow
local XUiLilithGachaShow = XLuaUiManager.Register(require('XUi/XUiGachaCanLiver/XUiGachaCanLiverDrawShow/XUiGachaCanLiverDrawShow'), 'UiLilithGachaShow')

---@overload
function XUiLilithGachaShow:OnStart(gachaId, rewardList, closeCb)
    self.Super.OnStart(self, gachaId, rewardList)
    self:RegisterClickEvent(self.BtnSkip, self.OnBtnSkipClick)
    self.CloseCb = closeCb
    
    self.IsOne = XTool.GetTableCount(self.RewardList) == 1
    
    self.PurpleEffectPath = XGachaConfigs.GetClientConfig('LilithDrawCardEffects', 1)
    self.YellowEffectPath = XGachaConfigs.GetClientConfig('LilithDrawCardEffects', 2)
    self.RedEffectPath = XGachaConfigs.GetClientConfig('LilithDrawCardEffects', 3)

    self.WhiteExposureEffectPath = XGachaConfigs.GetClientConfig('LilithDrawCardExposureEffects', 1)
    self.PurpleExposureEffectPath = XGachaConfigs.GetClientConfig('LilithDrawCardExposureEffects', 2)
    self.YellowExposureEffectPath = XGachaConfigs.GetClientConfig('LilithDrawCardExposureEffects', 3)
    self.RedExposureEffectPath = XGachaConfigs.GetClientConfig('LilithDrawCardExposureEffects', 4)

    self:InitCardEffectByQuality()
    self:PlayFirstPeriodAnimation()
end

--- 根据对应奖励的品质，初始化映射的UI上的特效资源
function XUiLilithGachaShow:InitCardEffectByQuality()
    local maxQuality = 0
    
    if self.IsOne then
        local reward = self.RewardList[1]
        local quality = self:GetQualityByRewardInfo(reward)
        maxQuality = quality
        local effectPath = self:GetEffectPathByQuality(quality)

        if not string.IsNilOrEmpty(effectPath) then
            self.FxCardOne:LoadPrefab(effectPath)
        end
    else
        
        for i, reward in pairs(self.RewardList) do
            local quality = self:GetQualityByRewardInfo(reward)

            if quality > maxQuality then
                maxQuality = quality
            end
            
            local effectPath = self:GetEffectPathByQuality(quality)

            if not string.IsNilOrEmpty(effectPath) then
                local fxObj = self['FxCard'..i]

                if fxObj then
                    fxObj:LoadPrefab(effectPath)
                end
            end
        end
    end
    
    local exposureEffectPath = self:GetExposureEffectPathByQuality(maxQuality)
    local effectPath = self:GetEffectPathByQuality(maxQuality)

    if not string.IsNilOrEmpty(effectPath) then
        self.EffectBest:LoadPrefab(effectPath)
    end

    if not string.IsNilOrEmpty(exposureEffectPath) then
        self.EffectExposure:LoadPrefab(exposureEffectPath)
    end
end

function XUiLilithGachaShow:GetEffectPathByQuality(quality)
    quality = quality or 4
    if quality == 4 then
        return self.PurpleEffectPath
    elseif quality == 5 then
        return self.YellowEffectPath
    elseif quality == 6 then
        return self.RedEffectPath
    end
end

function XUiLilithGachaShow:GetExposureEffectPathByQuality(quality)
    quality = quality or 4
    if quality == 4 then
        return self.PurpleExposureEffectPath
    elseif quality == 5 then
        return self.YellowExposureEffectPath
    elseif quality == 6 then
        return self.RedExposureEffectPath
    else
        return self.WhiteExposureEffectPath
    end
end

--- 一阶段动画是不管几抽都共用的演出动画
function XUiLilithGachaShow:PlayFirstPeriodAnimation()
    local isSuccessBegin = false
    
    self:PlayAnimation('BeginEnable', function() 
        self:PlaySecondPeriodAnimation()
    end, function()
        isSuccessBegin = true
    end, CS.UnityEngine.Playables.DirectorWrapMode.None)

    if not isSuccessBegin then
        self:PlaySecondPeriodAnimation()
    end
end

--- 二阶段动画是展示抽出n张卡牌（对应n抽）需要根据当前是几抽来控制播不同的动画
function XUiLilithGachaShow:PlaySecondPeriodAnimation()
    local callback = function() 
        self:DoClose()
    end
    
    local isSuccessBegin = false

    local beginCallback = function()
        isSuccessBegin = true
    end

    if self.IsOne then
        self:PlayAnimation('1SpinEnable', callback, beginCallback)
    else
        self:PlayAnimation('10SpinEnable', callback, beginCallback)
    end

    if not isSuccessBegin then
        callback()
    end
end

function XUiLilithGachaShow:OnBtnSkipClick()
    self:StopAnimation("BeginEnable", true)
    self:StopAnimation("1SpinEnable", true)
    self:StopAnimation("10SpinEnable", true)
    
    self:DoClose(true)
end

function XUiLilithGachaShow:DoClose(isSkip)
    if self.CloseCb then
        -- 这里特殊约定回调中会使用PopThenOpen来关闭当前界面，因此不执行Close
        self.CloseCb(isSkip)
        self.CloseCb = nil
    else
        self:Close()
    end
end

return XUiLilithGachaShow