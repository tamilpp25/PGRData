local XUiPanelNameplate = XClass(nil, "XUiPanelNameplate")

function XUiPanelNameplate:Ctor(ui, rootUi)
    self.RootUi = rootUi
    self.Transform = ui.transform
    self.GameObject = ui.gameObject
    XTool.InitUiObject(self)
   
    self.Enablenim = self.Transform:Find("Animation/EffectEnable")
    XEventManager.AddEventListener(XEventId.EVENT_CHAT_CLOSE_NAMEPLATE, self.PlayCloseAnim, self)
end

-- 仅聊天窗口需要播放特效淡出动画
function XUiPanelNameplate:PlayCloseAnim(id)
    if self.EffectGo and not XTool.UObjIsNil(self.EffectGo) then
        self.CloseAnim = self.EffectGo.transform:Find("Animation/Disable")
        if self.CloseAnim and self.CloseAnim.gameObject.activeInHierarchy then
            self.CloseAnim:PlayTimelineAnimation()
        end
    end
    XEventManager.RemoveEventListener(XEventId.EVENT_CHAT_CLOSE_NAMEPLATE, self.PlayCloseAnim)
end

function XUiPanelNameplate:UpdateDataById(id)
    local imageWidth = 0
    self.PanelGold.gameObject:SetActiveEx(true)
    self.PanelSilver.gameObject:SetActiveEx(false)
    self.PanelCopper.gameObject:SetActiveEx(false)
    if self.PanelNew then
        self.PanelNew.gameObject:SetActiveEx(false)
    end

    local setSpriteCb = function ()
        -- 自适应聊天铭牌宽度
        local originPicSize = self.ImgGold.sprite.bounds.size * 100
        imageWidth = originPicSize.x
        if imageWidth > 0 then
            self.GameObject:GetComponent("LayoutElement").preferredWidth = imageWidth + 7.5
            self.ImgGold.gameObject:GetComponent("RectTransform").sizeDelta = Vector2(imageWidth, originPicSize.y)
        end
    end

    if XMedalConfigs.GetNameplateIconType(id) == XMedalConfigs.NameplateShow.ShowIcon then
        self.ImgGold:SetSprite(XMedalConfigs.GetNameplateIcon(id), setSpriteCb)
        self.TxtGold.gameObject:SetActiveEx(false)
    else
        local icon, title = XMedalConfigs.GetNameplateIcon(id)
        self.ImgGold:SetSprite(icon, setSpriteCb)
        self.TxtGold.gameObject:SetActiveEx(true)
        self.TxtGold.text = title
        local outLineClolor = XMedalConfigs.GetNameplateOutLineColor(id)
        if outLineClolor then
            self.TxtGoldOutLine.effectColor = XUiHelper.Hexcolor2Color(XMedalConfigs.GetNameplateOutLineColor(id))
        end
    end

    -- 特效
    local lp = nil
    if self.Effect then
        lp = self.Effect:GetComponent("XUiLoadPrefab")
    else
        return
    end
    local currInstatiePrefabUrl = lp and lp.PrefabAssetUrl or nil
    local res = XMedalConfigs.GetNameplateEffectRes(id) 
    
    if res then
        self.Effect.gameObject:SetActiveEx(true)
        self.EffectGo = self.Effect:LoadPrefab(res)
        self.EffectGo.gameObject:SetActiveEx(true)
        self.Enablenim.gameObject:SetActiveEx(true)

        if not XTool.UObjIsNil(self.EffectGo) and res ~= currInstatiePrefabUrl then -- 防止重复Init
            XScheduleManager.ScheduleOnce(function()
                if XTool.UObjIsNil(self.Effect) then
                    return
                end
                self.Effect:GetComponent("XUiEffectLayer"):Init()   -- 延时初始化，因为自动初始化过早，render还未加载出来
            end, 50)
        end
    else
        self.Enablenim.gameObject:SetActiveEx(false)    -- 特效的淡入动画自动播放，为了防止无特效数据替换原本有特效数据的铭牌也播放该动画，需要将其隐藏
        self.Effect.gameObject:SetActiveEx(false)
    end
    
    -- mask
    local maskRect = nil
    local tempMaskList = self.Effect:GetComponentsInParent(typeof(CS.UnityEngine.Transform), true)
    for i = 1, tempMaskList.Length - 1 do --向上查找到最近的Mask 适配特效遮罩
        if tempMaskList[i].name == "Viewport" then
            local mask = tempMaskList[i]:GetComponent("Mask")
            local mask2d = tempMaskList[i]:GetComponent("RectMask2D")
            if mask or mask2d then
                maskRect = tempMaskList[i]
                break
            end
        end 
    end
  
    if maskRect and maskRect.name == "Viewport" then
        local maskComp = self.Effect:GetComponent("XUiEffectMaskObject")
        maskComp.Mask = maskRect
    end

    -- if Quality == XMedalConfigs.NameplateQuality.Copper then
    --     self.PanelGold.gameObject:SetActiveEx(false)
    --     self.PanelSilver.gameObject:SetActiveEx(false)
    --     self.PanelCopper.gameObject:SetActiveEx(true)
    --     --self.ImgCopper:SetSprite("")
    --     self.TxtCopper.text = Title
    -- elseif Quality == XMedalConfigs.NameplateQuality.Silver then
    --     self.PanelGold.gameObject:SetActiveEx(false)
    --     self.PanelSilver.gameObject:SetActiveEx(true)
    --     self.PanelCopper.gameObject:SetActiveEx(false)
    --     --self.ImgSilver:SetSprite("")
    --     self.TxtSilver.text = Title
    -- elseif Quality == XMedalConfigs.NameplateQuality.Gold then
    --     self.PanelGold.gameObject:SetActiveEx(true)
    --     self.PanelSilver.gameObject:SetActiveEx(false)
    --     self.PanelCopper.gameObject:SetActiveEx(false)
    --     --self.ImgGold:SetSprite("")
    --     self.TxtGold.text = Title
    -- end
end

function XUiPanelNameplate:SetEffectActive(isActive)
    if not XTool.UObjIsNil(self.EffectGo) then
        self.EffectGo.gameObject:SetActiveEx(isActive)
    end
end

return XUiPanelNameplate