---@class XUiGridAreaWarBlock Block
---@field Transform UnityEngine.Transform
---@field GameObject UnityEngine.GameObject
local XUiGridAreaWarBlock = XClass(nil, "XUiGridAreaWarBlock")

local Decimal = 10 ^ 2 --保留2位小数


function XUiGridAreaWarBlock:Ctor(ui, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.ClickCb = clickCb

    XTool.InitUiObject(self)
    if self.BtnClick then
        self.BtnClick.CallBack = handler(self, self.OnClick)
    end
    if self.EffectAttack then
        self.EffectAttack.gameObject:SetActiveEx(false)
    end
    self:SetFighting(false)
    
    self.HideMaskCb = handler(self, self._HideMask)

    self.PanelJdEnable = self.Transform:FindTransform("PanelJdEnable")
    self.PanelJdDisable = self.Transform:FindTransform("PanelJdDisable")
    self.PanelMiniEnable = self.Transform:FindTransform("PanelMiniEnable")
    self.PanelMiniDisable = self.Transform:FindTransform("PanelMiniDisable")
    local animEnable = self.Transform:FindTransform("AnimEnable")

    if animEnable then
        ---@type UnityEngine.Playables.PlayableDirector
        self.AnimEnableDirector = animEnable.transform:GetComponent(typeof(CS.UnityEngine.Playables.PlayableDirector))
    end
    
    self.GridScale = self.Transform.localScale.x
end

function XUiGridAreaWarBlock:Refresh(blockId, isRepeatChallenge)
    --初始区块不做更新
    if XAreaWarConfigs.IsInitBlock(blockId) then
        return
    end

    self.BlockId = blockId
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

--战斗中状态
function XUiGridAreaWarBlock:SetFighting(value)
    if self.PanelSelect then
        self.PanelSelect.gameObject:SetActiveEx(value)
    end
end

function XUiGridAreaWarBlock:OnClick()
    if self.ClickCb then
        self.ClickCb(self.BlockId)
    end
end

function XUiGridAreaWarBlock:SetVisible(visible)
    if not XTool.UObjIsNil(self.AnimEnableDirector) then
        self.AnimEnableDirector.playOnAwake = not self.IsSmall
    end
    self.GameObject:SetActiveEx(visible)
end

function XUiGridAreaWarBlock:PlayNearAnim()
    self:TryPlayTimeLineAnimation(self.PanelJdEnable, true)
end

function XUiGridAreaWarBlock:PlayFarAnim()
    self:TryPlayTimeLineAnimation(self.PanelJdDisable, true)
end

function XUiGridAreaWarBlock:PlayMiniEnable()
    if XTool.UObjIsNil(self.PanelMiniEnable) then
        return
    end
    if self.IsSmall or not (self.PanelMiniEnable.gameObject.activeInHierarchy) then
        return
    end
    self.IsSmall = true
    self:TryPlayTimeLineAnimation(self.PanelMiniEnable)
end

function XUiGridAreaWarBlock:PlayMiniDisable()
    if XTool.UObjIsNil(self.PanelMiniDisable) then
        return
    end
    if not self.IsSmall or not (self.PanelMiniDisable.gameObject.activeInHierarchy) then
        return
    end
    self.IsSmall = false
    self:TryPlayTimeLineAnimation(self.PanelMiniDisable)
end

function XUiGridAreaWarBlock:_HideMask()
    XLuaUiManager.SetMask(false)
end

---@param transform UnityEngine.Transform
function XUiGridAreaWarBlock:TryPlayTimeLineAnimation(transform, isShowMask)
    if XTool.UObjIsNil(transform) then
        return
    end

    if not (transform.gameObject.activeInHierarchy) then
        return
    end
    local func
    if isShowMask then
        XLuaUiManager.SetMask(true)
        func =  self.HideMaskCb
    end
    transform:PlayTimelineAnimation(func)
end

--- 旋转
---@param angle UnityEngine.Quaternion
--------------------------
function XUiGridAreaWarBlock:Rotate(angle)
    if not XTool.UObjIsNil(self.PanelRotate) then
        self.PanelRotate.transform.localRotation = angle
    end
end

function XUiGridAreaWarBlock:GetLinePoint(index)
    index = index or 1
    local obj = self["ImgPoint"..index]
    local parentPos = self.Transform.parent.localPosition
    if not obj then
        XLog.Error("创建连线失败!" .. self.GameObject.name .. ", 第" .. index .. "个节点!")
        return parentPos
    end
    return parentPos + (obj.transform.localPosition * self.GridScale)
end


return XUiGridAreaWarBlock
