# Google 登入設定指南（中文）

## 問題：「無效」或「Provider is not enabled」

如果點擊「Continue with Google」後顯示無效或錯誤，通常是以下原因：

### 1. ⚠️ Supabase 沒有啟用 Google 登入（最常見）

**立即修復（2分鐘）：**

1. **打開 Supabase Dashboard**
   - 前往：https://app.supabase.com/
   - 登入你的帳號
   - 選擇你的專案（你的專案 URL：`https://ifzyoyaiqtevrchjdfsh.supabase.co`）

2. **啟用 Google Provider**
   ```
   左側選單：Authentication
        ↓
   上方標籤：Providers
        ↓
   找到：Google
        ↓
   開關切換為：ON（綠色）✅
        ↓
   點擊：Save
   ```

3. **重新啟動 App**
   ```bash
   flutter run
   ```

這樣就能修復「provider is not enabled」的錯誤了！

---

### 2. 🔑 設定 Google OAuth（完整功能，需要 10 分鐘）

啟用上面的開關後，還需要設定 Google 憑證才能真正使用：

#### 步驟 A: Google Cloud Console

1. **前往 Google Cloud Console**
   - https://console.cloud.google.com/

2. **建立專案**（如果還沒有）
   - 點擊頂部專案選單 → 「新增專案」
   - 專案名稱：例如「My Music App」
   - 點擊「建立」

3. **啟用 Google+ API**
   - 左側選單：APIs & Services → Library
   - 搜尋：「Google+ API」
   - 點擊「Enable」

4. **設定 OAuth 同意畫面**
   - 左側選單：APIs & Services → OAuth consent screen
   - 選擇：**External（外部）**
   - 點擊「建立」
   
   填寫必填欄位：
   - **應用程式名稱**：你的 App 名稱
   - **使用者支援電子郵件**：你的信箱
   - **開發人員聯絡資訊**：你的信箱
   - 點擊「儲存並繼續」
   
   範圍（Scopes）：
   - 點擊「新增或移除範圍」
   - 勾選：`/auth/userinfo.email`
   - 勾選：`/auth/userinfo.profile`
   - 勾選：`openid`
   - 點擊「更新」
   - 點擊「儲存並繼續」
   
   測試使用者：
   - **點擊「新增使用者」**
   - **輸入你的 Gmail 信箱**（測試時要用這個帳號登入）
   - 點擊「新增」
   - 點擊「儲存並繼續」

5. **建立 OAuth 用戶端 ID**
   - 左側選單：APIs & Services → Credentials
   - 點擊「建立憑證」→「OAuth 用戶端 ID」
   - 應用程式類型：選擇 **網頁應用程式**
   - 名稱：「Supabase Auth」
   
   **已授權的重新導向 URI**（重要！）：
   - 點擊「新增 URI」
   - 輸入：
     ```
     https://ifzyoyaiqtevrchjdfsh.supabase.co/auth/v1/callback
     ```
     ⚠️ 注意：
     - 必須使用你的 Supabase URL
     - 結尾是 `/auth/v1/callback`
     - 不要有多餘的斜線
   
   - 點擊「建立」
   - **複製 Client ID** （長得像：123456789-abc.apps.googleusercontent.com）
   - **複製 Client Secret** （保密！）

#### 步驟 B: 在 Supabase 設定 Google 憑證

1. **回到 Supabase Dashboard**
   - Authentication → Providers → Google

2. **貼上憑證**
   - **Client ID (for OAuth)**：貼上剛才複製的 Client ID
   - **Client Secret (for OAuth)**：貼上剛才複製的 Client Secret

3. **儲存**
   - 點擊「Save」按鈕

---

## 完整測試步驟

1. **確認 Supabase 設定**
   - ✅ Google Provider 開關是 ON
   - ✅ Client ID 已填入
   - ✅ Client Secret 已填入
   - ✅ 已點擊 Save

2. **確認 Google Console 設定**
   - ✅ OAuth 用戶端已建立
   - ✅ Redirect URI 正確：`https://ifzyoyaiqtevrchjdfsh.supabase.co/auth/v1/callback`
   - ✅ 你的 Gmail 已加入測試使用者

3. **重新執行 App**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

4. **測試登入**
   - 點擊「Continue with Google」
   - 應該會開啟瀏覽器
   - 選擇你的 Google 帳號（測試使用者）
   - 同意權限
   - 自動返回 App
   - ✅ 登入成功！

---

## 常見錯誤與解決方法

### ❌ 錯誤：「provider is not enabled」
**原因**：Supabase 沒有啟用 Google
**解決**：
1. Supabase Dashboard → Authentication → Providers
2. 找到 Google，切換為 ON
3. 點擊 Save

### ❌ 錯誤：「redirect_uri_mismatch」
**原因**：Google Console 的 Redirect URI 設定錯誤
**解決**：
1. Google Cloud Console → APIs & Services → Credentials
2. 點擊你的 OAuth 用戶端
3. 已授權的重新導向 URI 確認是：
   ```
   https://ifzyoyaiqtevrchjdfsh.supabase.co/auth/v1/callback
   ```
4. 儲存

### ❌ 錯誤：「Access blocked: This app's request is invalid」
**原因**：OAuth 同意畫面設定不完整，或未加入測試使用者
**解決**：
1. Google Cloud Console → OAuth consent screen
2. 檢查所有必填欄位是否填寫
3. 到「Test users」頁面
4. 新增你要測試的 Gmail 帳號
5. 儲存

### ❌ 瀏覽器開啟後沒反應
**原因**：Deep linking 問題
**解決**：
1. 確認 AndroidManifest.xml 有正確設定（已設定好）
2. 清理並重新建置：
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

### ❌ 按鈕按下去沒反應
**原因**：Supabase URL 或 Key 可能有問題
**解決**：
1. 檢查 `.env` 檔案：
   ```
   SUPABASE_URL=https://ifzyoyaiqtevrchjdfsh.supabase.co
   SUPABASE_ANON_KEY=eyJ...（你的 key）
   ```
2. 確認沒有多餘空格
3. 重新執行 App

---

## 快速檢查清單

執行前確認：

**Supabase 設定：**
- [ ] Google Provider 開關是 ON（綠色）
- [ ] （選填）Client ID 已填入
- [ ] （選填）Client Secret 已填入
- [ ] 點擊了 Save 按鈕

**Google Cloud Console：**
- [ ] 已建立 OAuth 用戶端 ID
- [ ] Redirect URI 是：`https://ifzyoyaiqtevrchjdfsh.supabase.co/auth/v1/callback`
- [ ] 已加入測試使用者（你的 Gmail）
- [ ] OAuth 同意畫面已設定完成

**App 設定：**
- [ ] `.env` 檔案有正確的 SUPABASE_URL 和 SUPABASE_ANON_KEY
- [ ] 已重新執行 `flutter run`

---

## 看到詳細錯誤訊息

現在 App 會顯示詳細的錯誤訊息：

1. **點擊「Continue with Google」**
2. **如果有錯誤**，會出現紅色通知
3. **點擊通知上的「詳情」**
4. **會看到完整的錯誤碼和訊息**
5. **把錯誤訊息貼給我，我可以幫你解決！**

---

## 需要協助？

如果照著上面做還是不行，請提供：

1. **完整的錯誤訊息**（點擊「詳情」看到的內容）
2. **Supabase Dashboard 的截圖**（Authentication → Providers → Google）
3. **Google Console 的截圖**（Redirect URI 那部分）

我會幫你找出問題！

---

## 簡易版設定（只為了測試，不需要 Google OAuth）

如果只是想先測試一下，暫時不想設定完整的 Google OAuth：

1. **只需要啟用 Supabase 的 Google Provider**
   - Dashboard → Authentication → Providers → Google
   - 切換為 ON
   - **不用填** Client ID 和 Secret
   - 點擊 Save

2. **這樣可以避免「provider not enabled」錯誤**
3. **但實際點擊登入會失敗**（因為沒有憑證）
4. **等有空再補上 Google OAuth 憑證即可**

---

**祝你設定順利！有問題隨時問我 😊**
