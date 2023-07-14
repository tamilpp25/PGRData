local XUiLoading = XLuaUiManager.Register(XLuaUi, "UiLoading")

function XUiLoading:OnAwake()
    XTool.InitUiObject(self)
end

function XUiLoading:OnStart(stageLoadingType)
    local title, desc, image, spine
    local loadingTab, loadingType = XDataCenter.LoadingManager.GetLoadingTab(stageLoadingType)

    if not loadingTab then
        return
    end

    if loadingType == XSetConfigs.LoadingType.Custom then
        title = loadingTab:GetName()
        desc = loadingTab:GetDesc()
        image = loadingTab:GetBg()

        if XLoadingConfig.GetCustomUseSpine() then
            spine = loadingTab:GetSpineBg()
        end
    else
        title = loadingTab.Title
        desc = loadingTab.Desc
        image = loadingTab.ImageUrl
    end

    --设置spine动画
    if spine then
        self.Bg.gameObject:SetActiveEx(false)
        self.SpineRoot.gameObject:SetActiveEx(true)
        self.SpineRoot:LoadPrefab(spine)
        --设置背景
    elseif image then
        self.Bg = self.Bg:SetRawImage(image)
    else
        self.Bg.texture = nil
    end

    --设置标题
    if title then

        self.TitleText.gameObject:SetActive(true)
        self.TitleText.text = title

        --设置内容
        if desc then
            self.Desc.gameObject:SetActive(true)
            self.Desc.text = string.gsub(desc, "\\n", "\n")
        else
            self.Desc.gameObject:SetActive(false)
        end

    else
        self.TitleText.gameObject:SetActive(false)
    end

end