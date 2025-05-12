local XUiGridAreaWarBlockCommon = require("XUi/XUiAreaWar/XUiGridAreaWarBlockCommon")

---@class XUiGridAreaWarBlock : XUiGridAreaWarBlockCommon
---@field Transform UnityEngine.Transform
---@field GameObject UnityEngine.GameObject
local XUiGridAreaWarBlock = XClass(XUiGridAreaWarBlockCommon, "XUiGridAreaWarBlock")

local Decimal = 10 ^ 2 --保留2位小数

function XUiGridAreaWarBlock:InitUi(clickCb)
    self.ClickCb = clickCb
end

function XUiGridAreaWarBlock:Refresh(blockId, isRepeatChallenge)
    self.BlockId = blockId
    --初始区块不做更新
    if XAreaWarConfigs.IsInitBlock(blockId) then
        return
    end
    local block = XDataCenter.AreaWarManager.GetBlock(blockId)

    if XAreaWarConfigs.CheckBlockShowType(blockId, XAreaWarConfigs.BlockShowType.NormalCharacter) then
        if self.RImgRole then
            local icon = XAreaWarConfigs.GetRoleBlockIcon(blockId)
            if icon then
                self.RImgRole:SetRawImage(icon)
            end
        end
    end

    if self.TxtName then
        self.TxtName.text = XAreaWarConfigs.GetBlockNameEn(blockId)
    end

    if self.TxtTime then
        local tips = ""
        if XDataCenter.AreaWarManager.GetBlockUnlockLeftTime(blockId) > 0 then
            --优先判断时间是否达到
            local openTime = XDataCenter.AreaWarManager.GetBlockUnlockTime(blockId)
            local timeFormat = CsXTextManagerGetText("AreaWarBlockLockTimeFormat")
            tips =
                CsXTextManagerGetText("AreaWarBlockLockTime", XTime.TimestampToGameDateTimeString(openTime, timeFormat))
        else
            tips = CsXTextManagerGetText("AreaWarBlockLock")
        end
        tips = XUiHelper.ConvertLineBreakSymbol(tips)
        self.TxtTime.text = tips
    end
    
    local isClear = XDataCenter.AreaWarManager.IsBlockClear(blockId) --已净化
    local isFighting = XDataCenter.AreaWarManager.IsBlockFighting(blockId) --战斗中
    local isLock = XDataCenter.AreaWarManager.IsBlockLock(blockId) --未解锁
    if self.EffectClear then
        self.EffectClear.gameObject:SetActiveEx(isClear and not isRepeatChallenge)
    end
    if self.EffectDisable then
        self.EffectDisable.gameObject:SetActiveEx(isLock)
    end
    if self.EffectNormal then
        self.EffectNormal.gameObject:SetActiveEx(isFighting and not isRepeatChallenge)
    end
    if self.EffectRepeat then
        self.EffectRepeat.gameObject:SetActiveEx(not isLock and isRepeatChallenge)
    end
    if self.PanelClear then
        self.PanelClear.gameObject:SetActiveEx(isClear)
    end
    if self.PanelDisable then
        self.PanelDisable.gameObject:SetActiveEx(isLock)
    end
    if self.PanelNormal then
        self.PanelNormal.gameObject:SetActiveEx(isFighting)
    end

    self.ImgType.gameObject:SetActiveEx(isFighting or isRepeatChallenge)
    if isFighting or isRepeatChallenge then
        self.ImgType:SetSprite(XAreaWarConfigs.GetBlockLevelTypeMapIcon(blockId))
    end

        --进度条
    local progress = block:GetProgress()
    if self.RImgJd then
        self.RImgJd.fillAmount = progress
    end
    if self.TxtProgress then
        self.TxtProgress.text = math.floor(progress * 100 * Decimal) / Decimal .. "%"
    end

    --作战中特效
    self:SetFighting(isFighting)
end

function XUiGridAreaWarBlock:OnClick()
    if self.ClickCb then
        self.ClickCb(self.BlockId)
    end
end

function XUiGridAreaWarBlock:GetBindParam()
    return self.BlockId
end

return XUiGridAreaWarBlock
