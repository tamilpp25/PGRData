local XPanelNieREasterEggChat = XClass(nil, "XPanelNieREasterEggChat")

local NieREasterEggBulletChatDelayTime = CS.XGame.ClientConfig:GetFloat("NieREasterEggBulletChatDelayTime")
local NieREasterEggBulletChatShowTime = CS.XGame.ClientConfig:GetFloat("NieREasterEggBulletChatShowTime")

function XPanelNieREasterEggChat:Ctor(ui, rootUi)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    
    XTool.InitUiObject(self)
    local width = CS.XUiManager.RealScreenWidth
    local height = CS.XUiManager.RealScreenHeight
    self.LengthMin = math.ceil(math.sqrt(width ^ 2 + height ^ 2) / 2)
    self.TextObj2List = {}
    
    self.TextTypeWriter = self.Text.gameObject:GetComponent("TextTypewriter")

    self.TextObjList = {}
    self.UseTextDic = {}
    for i = 1, 6 do
        local tmpI = {}
        tmpI.Text = self["Text"..i]
        tmpI.CanvasGroup = self["Text"..i].gameObject:GetComponent("CanvasGroup")
        tmpI.CanvasGroup.alpha = 0
        tmpI.Name = self["Name"..i]
        self.TextObjList[i] = tmpI
    end
end

function XPanelNieREasterEggChat:ResetAll()
    self:StopBulletTimer()
    for i = 1, 6 do
        self.TextObjList[i].CanvasGroup.alpha = 0
    end
    
end

function XPanelNieREasterEggChat:PlayEndStory()
    self.RootUi:HideBtn()
end

function XPanelNieREasterEggChat:PlayStoryInfo(storyConfig)
    self.RootUi:HideBtn()
    self.TextTypeWriter.CompletedHandle = function()
        self.RootUi:ShowStoryBtn()
    end
    self.Text.text = storyConfig.Desc
    self.TextTypeWriter:Play()
    self.Text.gameObject:SetActiveEx(true)
end

function XPanelNieREasterEggChat:PlayBulletChat()
    local index = 1
    local count = 1
    local bulletList = XDataCenter.NieRManager.GetNieREasterEggData()
    local ageStr = CS.XTextManager.GetText("NieREasterEggAgeStr")
    local maxMessgaeCount = XDataCenter.NieRManager.GetCurMaxEasterEggMessageCount()
    local delayTime = NieREasterEggBulletChatDelayTime * 1000 
    local timeTween = NieREasterEggBulletChatShowTime
    local timeTween1 = timeTween / 2
    
    local PlayBulletFunc = function()
        if self.UseTextDic[index] then
            return 
        end
        if count > maxMessgaeCount then
            self:StopBulletTimer()
            return 
        end
        local tmpObj = self.TextObjList[index]
        self.UseTextDic[index] = true
        
        local bullet = bulletList[count]
        if not bullet then return  end
        local playerName = bullet.PlayerName
        local message = XNieRConfigs.GetNieREasterEggMessageConfigById(bullet.MessageId).Message
        local label = XNieRConfigs.GetNieREasterEggLabelConfigById(bullet.LabelId).Label
        local age = bullet.Age
        tmpObj.Text.text = string.format("\"%s\"", message)
        tmpObj.Name.text = CS.XTextManager.GetText("NieREasterEggLabelStr", playerName, age, ageStr, label)
        XUiHelper.DoAlpha(tmpObj.CanvasGroup, 0, 1, timeTween,  XUiHelper.EaseType.Linear,function()
            self.UseTextDic[index] = false
        end)
        if index > 1 then
            local lastIndex = index - 1
            local lastTmpObj = self.TextObjList[lastIndex]
            XUiHelper.DoAlpha(lastTmpObj.CanvasGroup, 1, 0.5, timeTween1,  XUiHelper.EaseType.Linear,function()
                self.UseTextDic[index] = false
            end)
        end
        index = index + 1
        count = count + 1
        index = index > 6 and 1 or index

        local nextObj = self.TextObjList[index]
        if nextObj.CanvasGroup.alpha == 0.5 and count < maxMessgaeCount then
            XUiHelper.DoAlpha(nextObj.CanvasGroup, 0.5, 0, timeTween1,  XUiHelper.EaseType.Linear,function()
                self.UseTextDic[index] = false
            end)
        end
    end
    
    PlayBulletFunc()
    self.Timer = XScheduleManager.ScheduleForever(function()
        PlayBulletFunc()
    end, delayTime)
end

function XPanelNieREasterEggChat:StopBulletTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end
-- function XPanelNieREasterEggChat:UpdateRealShowInfoSingle(isFirstDied, isWin)
--     local strShow = "153456465465465465465"
--     local txtShow
--     if self.TextPer then
--         txtShow = self.TextPer
--     else
--         local txtObj = CS.UnityEngine.Object.Instantiate(self.Text1)
--         txtObj.transform:SetParent(self.CenterPoint, false)
--         txtShow = txtObj.transform:GetComponent("Text")
--         self.TextPer = txtShow
--     end
--     txtShow.text = strShow
--     txtShow.gameObject:SetActiveEx(true)
-- end

-- function XPanelNieREasterEggChat:UpdateRealShowInfos()
--     local strShow = "153456465465465465465"
--     local txtShow
--     if self.TextPer then
--         txtShow = self.TextPer
--     else
--         local txtObj = CS.UnityEngine.Object.Instantiate(self.Text1)
--         txtObj.transform:SetParent(self.CenterPoint, false)
--         txtShow = txtObj.transform:GetComponent("Text")
--         self.TextPer = txtShow
--     end
--     txtShow.text = strShow
--     txtShow.gameObject:SetActiveEx(true)
    
--     local scin = 0
--     local timeTween = 10
--     local startScale = CS.UnityEngine.Vector3(2,2,2)
--     local endScale = CS.UnityEngine.Vector3(0.5, 0.5, 0.5)
--     local endPos = CS.UnityEngine.Vector3(0, 0, 0)
--     BULLET_CHAT_TIME = 150
--     self.Timer = XScheduleManager.Schedule(function()
--         local length = math.random(self.LengthMin, self.LengthMin + 500)
--         local argue = math.random(scin * 90, (scin + 1) * 90)
--         timeTween = math.random(10, 15)
--         scin = scin < 3 and scin + 1 or 0
--         local x = math.sin(math.rad(argue)) * length
--         local y = math.cos(math.rad(argue)) * length

--         local txtShow
--         local txtRect
--         local txtCanvasGroup
--         local tmpObj
--         if next(self.TextObj2List) ~= nil then
--             tmpObj = table.remove(self.TextObj2List)
--             txtShow = tmpObj.txtShow
--             txtRect = tmpObj.txtRect
--             txtCanvasGroup = tmpObj.txtCanvasGroup
--         else
--             local txtObj = CS.UnityEngine.Object.Instantiate(self.Text2)
--             txtObj.transform:SetParent(self.CenterPoint, false)
--             txtShow = txtObj.transform:GetComponent("Text")
--             txtRect = txtObj.transform:GetComponent("RectTransform")
--             txtCanvasGroup = txtObj.transform:GetComponent("CanvasGroup")
--             txtObj.gameObject:SetActiveEx(true)
--             tmpObj = {}
--             tmpObj.txtShow = txtShow
--             tmpObj.txtRect = txtRect
--             tmpObj.txtCanvasGroup = txtCanvasGroup
--         end

--         txtRect.anchoredPosition = CS.UnityEngine.Vector2(x, y)
--         txtRect.localScale = startScale
--         txtCanvasGroup.alpha = 1
--         XUiHelper.DoMove(txtRect, endPos, timeTween, XUiHelper.EaseType.Sin, function()
--             table.insert(self.TextObj2List, tmpObj)
--         end)
--         XUiHelper.DoAlpha(txtCanvasGroup, 1, 0, timeTween,  XUiHelper.EaseType.Sin,nil)
--         XUiHelper.DoScale(txtRect, startScale, endScale, timeTween,  XUiHelper.EaseType.Sin,nil)
--     end, BULLET_CHAT_TIME, BULLET_CHAT_NUM, 0)
-- end



return XPanelNieREasterEggChat