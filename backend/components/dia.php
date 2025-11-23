<?php 
namespace app\components;
use Yii;
use yii\base\Component;
use yii\base\InvalidConfigException;
use app\models\Satisfisleri;
use app\models\Satissatirlari; 
use app\models\Iadesatirlari; 
use app\models\CashRegisters;
use app\models\CariHareketler;
use app\models\Musteriler;
use app\models\Urunler;
use app\models\Satiscilar;
use app\models\SatinAlmaSiparisFisSatir;
use app\models\Branches;
use app\models\Warehouses;
use app\components\PythonDictConverter;
class Dia extends Component{
    private static $cached_session_id = null;
    private static $session_expire_time = null;

    private static function getDiaUrl($endpoint) {
        $baseUrl = Yii::$app->params['dia_base_url'];
        $endpoints = Yii::$app->params['dia_endpoints'];
        $url = $baseUrl . $endpoints[$endpoint];
        
        // Log ekle
        $logMessage = "=== getDiaUrl ===\n";
        $logMessage .= "Tarih: " . date('Y-m-d H:i:s') . "\n";
        $logMessage .= "Endpoint: " . $endpoint . "\n";
        $logMessage .= "Base URL: " . $baseUrl . "\n";
        $logMessage .= "Final URL: " . $url . "\n\n";
        //file_put_contents(\Yii::getAlias('@runtime/dia_url_log.txt'), $logMessage, FILE_APPEND | LOCK_EX);
        
        return $url;
    }

    public static function getsessionid(){
        if (self::$cached_session_id !== null &&  self::$session_expire_time !== null &&  time() < self::$session_expire_time) {
            return self::$cached_session_id;
        }
        $logMessage = "=== getsessionid BAŞLADI ===\n";
        $logMessage .= "Tarih: " . date('Y-m-d H:i:s') . "\n";
        
        $url =  self::getDiaUrl('sis');
        $logMessage .= "Login URL: " . $url . "\n";
    
        // SESSION ID MANUEL GİRİLMELİ
        $session_id = "";
        $firma_kodu = 1;
        $donem_kodu = 1;
        $username = Yii::$app->params['dia_user'];
        $password = Yii::$app->params['dia_pass'];
        $apikey = Yii::$app->params['dia_key'];
        
        $logMessage .= "Username: " . $username . "\n";
        $logMessage .= "API Key: " . $apikey . "\n";
        
        $data = <<<EOT
        {"login" :
            {"username": "$username",
             "password": "$password",
             "disconnect_same_user": "true",
             "lang": "uk", 
             "params": {"apikey": "$apikey"}
            }
        }
        
        EOT;
        
        $logMessage .= "Login Data: " . $data . "\n";
        
        $curl = curl_init();
        curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
        curl_setopt($curl, CURLOPT_POSTFIELDS, $data);
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($curl, CURLOPT_HTTPHEADER, array(
            'Content-Type: application/json',
            'Content-Length: ' . strlen($data))
        );
        curl_setopt($curl, CURLOPT_URL, $url);
        curl_setopt($curl, CURLOPT_TIMEOUT, 30);
        curl_setopt($curl, CURLOPT_CONNECTTIMEOUT, 10);
        curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);
        
        $logMessage .= "cURL seçenekleri ayarlandı\n";
        
        $result = curl_exec($curl);
        $httpCode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
        $curlError = curl_error($curl);
        $curlErrno = curl_errno($curl);
        
        $logMessage .= "cURL HTTP Code: " . $httpCode . "\n";
        $logMessage .= "cURL Error No: " . $curlErrno . "\n";
        $logMessage .= "cURL Error: " . $curlError . "\n";
        $logMessage .= "cURL Response: " . $result . "\n";
        
        curl_close($curl);
        
        $json=json_decode($result,true);
        $logMessage .= "JSON decode başarılı: " . (is_array($json) ? 'Evet' : 'Hayır') . "\n";
        if (is_array($json)) {
            $logMessage .= "JSON Response: " . print_r($json, true) . "\n";
        }
        
        // "session" değerini al
        $session_id = $json['msg'] ?? '';
        $logMessage .= "Session ID: " . $session_id . "\n";
        $logMessage .= "=== getsessionid TAMAMLANDI ===\n\n";
        
        // Log dosyasına yaz
        file_put_contents(\Yii::getAlias('@runtime/dia_session_log.txt'), $logMessage, FILE_APPEND | LOCK_EX);
        self::$cached_session_id = $session_id;
        self::$session_expire_time = time() + 300;
        return $session_id;
    }
    public static function getEkstre($carikod,$tarih,$detay,$tarih2,$ft){

        $url = self::getDiaUrl('rpr');
        // SESSION ID MANUEL GİRİLMELİ
        $session_id = Dia::getsessionid();
        $firma_kodu = 1;
        $donem_kodu = 1;
        $cari=Musteriler::find()->where(["Kod"=>$carikod])->one();
        if($cari==null)
            return ["sonuc"=>0,"hata"=>"Cari kod bulunamadı"];

        if($cari->_key==null)
            return ["sonuc"=>0,"hata"=>"Cari key bulunamadı"];
        $carikey=$cari->_key;
        $tarih1=date("Y-m-d");

        if($ft==0)
            $ft1="False";
        else 
            $ft1="True";
        $data = <<<EOT
        {"rpr_raporsonuc_getir" :
            {"session_id": "$session_id",
            "firma_kodu": $firma_kodu,
            "donem_kodu": $donem_kodu,
            "report_code":"scf1110a",
            "tasarim_key": 7609566,
        
            "param":  {
                "_key": "$carikey",
                "tarihbaslangic": "$tarih",
                "tarihbitis": "$tarih2",
                "tarihreferans": "$tarih1",
                "irsaliyeleriDahilEt":"$ft1",
                "vadeyontem": "B",
                "vadefarki": "0",
                "__ekparametreler": ["acilisbakiyesi","teslimolmamissiparisler"],
                "__fisturleri": [],
                "_key_sis_sube": 0,
                "_depolar" : [],
                "_subeler": [],
                "ustIslemTuruKeys": 0,
                "topluekstre": "False",
                "tekniksformgoster": "False",
                "basitsegosterme": $detay,
                "filtreler": [{"filtreadi": "vadetarihi",
                            "filtreturu": "aralik",
                            "ilkdeger": "2025-01-01",
                            "sondeger": "2025-12-31",
                            "serbest": ""
                            }],
                "siralama":[{"fieldname": "vadetarihi",
                            "sorttype": "asc"
                            }],
                "gruplama":[{"fieldname": "turu"}]
            },
            "format_type": "pdf"
            }
        }
        EOT;

        $curl = curl_init();
        curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
        curl_setopt($curl, CURLOPT_POSTFIELDS, $data);
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($curl, CURLOPT_HTTPHEADER, array(
            'Content-Type: application/json',
            'Content-Length: ' . strlen($data))
        );
        curl_setopt($curl, CURLOPT_URL, $url);
        $result = curl_exec($curl);

        $json=json_decode($result,true);
        curl_close($curl);
        $b64 = $json['result'] ?? null;

        if (!$b64) {
            throw new \yii\web\BadRequestHttpException('Missing "result"');
        }
    
        // Base64 -> binary
        $binary = base64_decode($b64, true);
        if ($binary === false) {
            throw new \yii\web\BadRequestHttpException('Invalid base64');
        }
    
        
        //PDF'i dosyaya yazmadan, direkt response olarak gönder
        return Yii::$app->response->sendContentAsFile(
            $binary,
            'document.pdf', // İstemcinin göreceği dosya adı
            [
                'mimeType' => 'application/pdf',
                'inline'   => false, // tarayıcıda/uygulamada görüntüle (indir yerine)
            ]
        );

        // $binary = base64_decode($b64, true);
        // if ($binary === false) {
        //     throw new \yii\web\BadRequestHttpException('Invalid base64');
        // }
    
        // $response = Yii::$app->response;
        // $response->format = \yii\web\Response::FORMAT_RAW;
        // $response->headers->set('Content-Type', 'application/pdf');
        // $response->headers->set('Content-Disposition', 'inline; filename="document.pdf"');
        // $response->headers->set('X-Content-Type-Options', 'nosniff');
        // $response->headers->set('Cache-Control', 'no-store');
        // $response->headers->set('Content-Length', (string)strlen($binary));
        // $response->content = $binary;
        // return $response;
    }
    public static function depoMiktar(){
        $url = self::getDiaUrl('rpr');

        $session_id = Dia::getsessionid();
        $firma_kodu = 1;
        $donem_kodu = 1;

        $data = [
            "rpr_raporsonuc_getir" => [
                "session_id" => $session_id,
                "firma_kodu" => $firma_kodu,
                "donem_kodu" => $donem_kodu,
                "report_code" => "scf2310a",
                "param" => [
                    "_depolar" => [],
                    "_key_sis_ozelkod1" => 0,
                    "_key_sis_ozelkod2" => 0,
                    "_key_sis_ozelkod3" => 0,
                    "_key_sis_ozelkod4" => 0,
                    "_key_sis_ozelkod5" => 0,
                    "_key_sis_ozelkod6" => 0,
                    "filtreler" => [],
                    "siralama" => [],
                    "gruplama" => [],
                    "pasiflerigoster" => false,
                    "depolardaolmayangoster" => false,
                    "stokkartkodu1" => "",
                    "stokkartkodu2" => "",
                    "stokkartturleri" => [],
                    "tasarim_key" => 0,
                    "ustIslemTuruKeys" => []
                ],
                "format_type" => "json"
            ]
        ];
        
        

        $jsonData = json_encode($data);
        $curl = curl_init();
        curl_setopt($curl, CURLOPT_URL, $url);
        curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($curl, CURLOPT_POSTFIELDS, $jsonData);
        curl_setopt($curl, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'Content-Length: ' . strlen($jsonData)
        ]);
        curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($curl, CURLOPT_TIMEOUT, 120); // 2 dakika toplam işlem süresi
        curl_setopt($curl, CURLOPT_CONNECTTIMEOUT, 30); // 30 saniye bağlantı zaman aşımı

        $result = curl_exec($curl);
        
        // Hata kontrolü ekleyelim
        if (curl_errno($curl)) {
            $error = curl_error($curl);
            curl_close($curl);
            Yii::error("cURL error: $error", __METHOD__);
            return ['error' => $error];
        }
        curl_close($curl);
        
        // Ham sonucu loglayalım
        Yii::info("Raw API response: $result", __METHOD__);
        
        try {
            $jsonResponse = json_decode($result, true);
            
            // Eğer result anahtarı varsa ve base64 encoded ise decode et
            if (isset($jsonResponse['result']) && is_string($jsonResponse['result'])) {
                $decodedResult = base64_decode($jsonResponse['result']);
                if ($decodedResult !== false) {
                    $decodedData = json_decode($decodedResult, true);
                    if ($decodedData !== null) {
                        $jsonResponse['result'] = $decodedData;
                    } else {
                        // Base64 decode başarılı ama JSON decode başarısız, ham string'i kullan
                        $jsonResponse['result'] = $decodedResult;
                    }
                } else {
                    Yii::warning("Base64 decode başarısız oldu", __METHOD__);
                }
            }
            
            return $jsonResponse["result"]["__rows"] ?? null;
        } catch (\Exception $e) {
            Yii::error("JSON decode error: " . $e->getMessage(), __METHOD__);
            return null;
        }
    }

    public static function getallproducts(){
        $url = self::getDiaUrl('scf');

            // SESSION ID MANUEL GİRİLMELİ
            $session_id =Dia::getsessionid();
            $firma_kodu = 1;
            $donem_kodu = 1;
            // "limit": 4,
            // "offset": 0
            $data = <<<EOT
            {"scf_stokkart_detay_listele" :
                {"session_id": "$session_id",
                "firma_kodu": $firma_kodu,
                "donem_kodu": $donem_kodu
                }
            }
            EOT;

            $curl = curl_init();
            curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
            curl_setopt($curl, CURLOPT_POSTFIELDS, $data);
            curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($curl, CURLOPT_HTTPHEADER, array(
                'Content-Type: application/json',
                'Content-Length: ' . strlen($data))
            );
            curl_setopt($curl, CURLOPT_URL, $url);
            $result = curl_exec($curl);
            curl_close($curl);
            return $result;
    }

    public static function getallcari(){
        $url = self::getDiaUrl('scf');

            // SESSION ID MANUEL GİRİLMELİ
            $session_id =Dia::getsessionid();
            $firma_kodu = 1;
            $donem_kodu = 1;
            // "limit": 4,
            // "offset": 0
            $data = <<<EOT
            {"scf_carikart_listele" :
                {"session_id": "$session_id",
                 "firma_kodu": $firma_kodu,
                 "donem_kodu": $donem_kodu
                }
            }
            EOT;

            $curl = curl_init();
            curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
            curl_setopt($curl, CURLOPT_POSTFIELDS, $data);
            curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($curl, CURLOPT_HTTPHEADER, array(
                'Content-Type: application/json',
                'Content-Length: ' . strlen($data))
            );
            curl_setopt($curl, CURLOPT_URL, $url);
            $result = curl_exec($curl);
            curl_close($curl);
            return $result;
    }
    

    public static function kampanyagetir(){
        $url =  self::getDiaUrl('scf');

        // SESSION ID MANUEL GİRİLMELİ
        $session_id = Dia::getsessionid();
        $firma_kodu = 1;
        $donem_kodu = 1;

        $data = <<<EOT
        {"scf_kampanya_listele" :
            {"session_id": "$session_id",
            "firma_kodu": $firma_kodu,
            "donem_kodu": $donem_kodu,
            "filters":"",
            "sorts": "",
            "params": "",
            "limit": 10,
            "offset": 0
            }
        }
        EOT;

        $curl = curl_init();
        curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
        curl_setopt($curl, CURLOPT_POSTFIELDS, $data);
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($curl, CURLOPT_HTTPHEADER, array(
            'Content-Type: application/json',
            'Content-Length: ' . strlen($data))
        );
        curl_setopt($curl, CURLOPT_URL, $url);
        $result = curl_exec($curl);

        $json=json_decode($result,true);
        curl_close($curl);
        return $json;
    }

    public static function kampanyafiyatlarigetir(){
        $url = self::getDiaUrl('scf');

        // SESSION ID MANUEL GİRİLMELİ
        $session_id = dia::getsessionid();
        $firma_kodu = 1;
        $donem_kodu = 1;
        
        $tarih = date('Y-m-d');

        $data = <<<EOT
        {
            "scf_fiyatkart_listele": {
                "session_id": "$session_id",
                "firma_kodu": $firma_kodu,
                "donem_kodu": $donem_kodu,
                "filters": [
                    {"field": "durum", "operator": "=", "value": "A"}
                ]
            }
        }
        EOT;
        
        $curl = curl_init();
        curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
        curl_setopt($curl, CURLOPT_POSTFIELDS, $data);
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($curl, CURLOPT_HTTPHEADER, array(
            'Content-Type: application/json',
            'Content-Length: ' . strlen($data))
        );
        curl_setopt($curl, CURLOPT_URL, $url);
        $result = curl_exec($curl);
        
        //$json=json_decode($result,true);
        curl_close($curl);
        return $result;
    }

    public static function stokbirimgetir(){
        $url = self::getDiaUrl('rpr');
        $session_id = Dia::getsessionid();
        $firma_kodu = 1;
        $donem_kodu = 1;

        $data =  [
            "rpr_raporsonuc_getir" => [
                "session_id" => $session_id,
                "firma_kodu" => 1,
                "donem_kodu" => 1,
                "report_code" => "scf2201c",
                "tasarim_key" => 3873238,
                "param" => [ "_key" => $keyno ],
                "format_type" => "pdf"
            ]
        ];

         $data =  [
            "scf_stokkart_birimleri_listele" =>[
                "session_id" => $session_id,
                "firma_kodu" => 1,
                "donem_kodu" => 1,
            ]

            
        ];
        $jsonData = json_encode($data);
        
            $curl = curl_init();
            curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
            curl_setopt($curl, CURLOPT_POSTFIELDS, $jsonData);
            curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
            // curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);
            // curl_setopt($curl, CURLOPT_SSL_VERIFYHOST, 0);
            curl_setopt($curl, CURLOPT_HTTPHEADER, array(
                'Content-Type: application/json',
                'Content-Length: ' . strlen($jsonData))
            );
      
             curl_setopt($curl, CURLOPT_URL, $url);
             $result = curl_exec($curl);
            if (curl_errno($curl)) {
                $hataMesaji = 'cURL hatası: ' . curl_error($curl) . ' - ' . date('Y-m-d H:i:s') . PHP_EOL;
            file_put_contents('runtime/curl_hatalari.txt', $hataMesaji, FILE_APPEND | LOCK_EX);
            } 
            else {
                $filePath = Yii::getAlias('@app/runtime/stokdata'.date("Ymdhis").'.txt');

                // Dosyaya yaz (JSON formatında yazıyoruz, ama istersen düz metin olarak da yazabilirsin)
                file_put_contents($filePath, json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
                echo ["sonuc"=>'@app/runtime/stokdata'.date("Ymdhis").'.txt'];
            }
    
            curl_close($curl);
            return;
    }

    public static function stokalimsatimanalizgetir($stokkodu){
        $timestamp = date("Ymdhis");
        $logFilePath = Yii::getAlias('@app/runtime/stokanaliz_detay_log_'.$timestamp.'.txt');
        
        // Detaylı log başlangıcı
        $logContent = "=== STOK ALIM SATIS ANALIZ DETAY LOG - " . date("Y-m-d H:i:s") . " ===\n";
        $logContent .= "Stok Kodu: " . $stokkodu . "\n";
        $logContent .= "Timestamp: " . $timestamp . "\n\n";
        
        try {
            // 1. URL alma
            $logContent .= "1. URL alma işlemi başladı\n";
            $url = self::getDiaUrl('rpr');
            $logContent .= "   URL alındı: " . $url . "\n\n";
            
            // 2. Session ID alma
            $logContent .= "2. Session ID alma işlemi başladı\n";
            $session_id = Dia::getsessionid();
            $logContent .= "   Session ID alındı: " . $session_id . "\n\n";
            
            // 3. Parametreler hazırlanıyor
            $logContent .= "3. Parametreler hazırlanıyor\n";
            $firma_kodu = 1;
            $donem_kodu = 1;
            $logContent .= "   Firma Kodu: " . $firma_kodu . "\n";
            $logContent .= "   Dönem Kodu: " . $donem_kodu . "\n\n";

            // 4. Data array oluşturma
            $logContent .= "4. Data array oluşturma\n";
            $data =  [
                "rpr_raporsonuc_getir" => [
                    "session_id" => $session_id,
                    "firma_kodu" => 1,
                    "donem_kodu" => 1,
                    "report_code" => "scf9007a",
                    "tasarim_key" => 1042,
                    "param" => [ 
                  
                            "param.stokkartkodu1" => $stokkodu,
                                
                                    ],
                    "format_type" => "pdf"
                ]
            ];
            $logContent .= "   Data array oluşturuldu\n";
            $logContent .= "   Report Code: scf9007a\n";
            $logContent .= "   Tasarim Key: 1042\n";
            $logContent .= "   Format Type: pdf\n\n";

            // 5. JSON encode işlemi
            $logContent .= "5. JSON encode işlemi\n";
            $jsonData = json_encode($data);
            $logContent .= "   JSON Data uzunluğu: " . strlen($jsonData) . " karakter\n";
            $logContent .= "   JSON Data: " . $jsonData . "\n\n";

            // 6. cURL başlatma
            $logContent .= "6. cURL başlatma\n";
            $curl = curl_init();
            $logContent .= "   cURL başlatıldı\n\n";

            // 7. cURL seçenekleri ayarlama
            $logContent .= "7. cURL seçenekleri ayarlama\n";
            curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
            $logContent .= "   CURLOPT_CUSTOMREQUEST: POST\n";
            
            curl_setopt($curl, CURLOPT_POSTFIELDS, $jsonData);
            $logContent .= "   CURLOPT_POSTFIELDS ayarlandı\n";
            
            curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
            $logContent .= "   CURLOPT_RETURNTRANSFER: true\n";
            
            curl_setopt($curl, CURLOPT_HTTPHEADER, array(
                'Content-Type: application/json',
                'Content-Length: ' . strlen($jsonData))
            );
            $logContent .= "   HTTP Headers ayarlandı\n";
            $logContent .= "   Content-Type: application/json\n";
            $logContent .= "   Content-Length: " . strlen($jsonData) . "\n";
            
            curl_setopt($curl, CURLOPT_URL, $url);
            $logContent .= "   URL ayarlandı: " . $url . "\n\n";

            // 8. cURL çalıştırma
            $logContent .= "8. cURL çalıştırma\n";
            $result = curl_exec($curl);
            $logContent .= "   cURL çalıştırıldı\n";
            $logContent .= "   Response uzunluğu: " . strlen($result) . " karakter\n\n";

            // 9. Hata kontrolü
            $logContent .= "9. Hata kontrolü\n";
            if (curl_errno($curl)) {
                $error = curl_error($curl);
                $logContent .= "   cURL HATASI: " . $error . "\n";
                curl_close($curl);
                
                // Log dosyasına yazma
                file_put_contents($logFilePath, $logContent);
                
                return ['error' => $error, 'log_file' => $logFilePath];
            } else {
                $logContent .= "   cURL hatası yok\n\n";
                
                // 10. Response işleme
                $logContent .= "10. Response işleme\n";
                
                // Ham response'u kaydet
                $hamFilePath = Yii::getAlias('@app/runtime/stokdata_ham_'.$timestamp.'.txt');
                $logContent .= "   Ham dosya yolu: " . $hamFilePath . "\n";
                $writeResult = file_put_contents($hamFilePath, $result);
                $logContent .= "   Ham dosya yazma sonucu: " . ($writeResult ? "Başarılı (".strlen($result)." byte)" : "Başarısız") . "\n";
                
                // JSON decoded response'u kaydet
                $logContent .= "   JSON decode işlemi başlıyor\n";
                $jsonResponse = json_decode($result, true);
                $jsonFilePath = Yii::getAlias('@app/runtime/stokdata_json_'.$timestamp.'.txt');
                $logContent .= "   JSON dosya yolu: " . $jsonFilePath . "\n";
                $jsonWriteResult = file_put_contents($jsonFilePath, json_encode($jsonResponse, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
                $logContent .= "   JSON dosya yazma sonucu: " . ($jsonWriteResult ? "Başarılı" : "Başarısız") . "\n";
                
                // Request data'sını da kaydet
                $requestFilePath = Yii::getAlias('@app/runtime/stokdata_request_'.$timestamp.'.txt');
                $logContent .= "   Request dosya yolu: " . $requestFilePath . "\n";
                $requestWriteResult = file_put_contents($requestFilePath, json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
                $logContent .= "   Request dosya yazma sonucu: " . ($requestWriteResult ? "Başarılı" : "Başarısız") . "\n\n";
                
                // JSON response analizi
                $logContent .= "11. JSON Response analizi\n";
                if ($jsonResponse) {
                    $logContent .= "   JSON decode başarılı\n";
                    $logContent .= "   Response keys: " . implode(', ', array_keys($jsonResponse)) . "\n";
                    if (isset($jsonResponse['code'])) {
                        $logContent .= "   Response code: " . $jsonResponse['code'] . "\n";
                    }
                    if (isset($jsonResponse['msg'])) {
                        $logContent .= "   Response message: " . $jsonResponse['msg'] . "\n";
                    }
                    if (isset($jsonResponse['result'])) {
                        $logContent .= "   Response result var: " . (is_array($jsonResponse['result']) ? count($jsonResponse['result']) . " adet" : "string") . "\n";
                    }
                } else {
                    $logContent .= "   JSON decode başarısız\n";
                    $logContent .= "   Ham response ilk 500 karakter: " . substr($result, 0, 500) . "\n";
                }
                
                curl_close($curl);
                $logContent .= "   cURL kapatıldı\n\n";
                
                // 12. Sonuç hazırlama
                $logContent .= "12. Sonuç hazırlama\n";
                $returnData = [
                    "success" => true,
                    "ham_sonuc" => $hamFilePath,
                    "json_sonuc" => $jsonFilePath,
                    "request_sonuc" => $requestFilePath,
                    "log_file" => $logFilePath,
                    "timestamp" => $timestamp
                ];
                $logContent .= "   Return data hazırlandı\n";
                $logContent .= "   Ham sonuç: " . $hamFilePath . "\n";
                $logContent .= "   JSON sonuç: " . $jsonFilePath . "\n";
                $logContent .= "   Request sonuç: " . $requestFilePath . "\n";
                $logContent .= "   Log dosyası: " . $logFilePath . "\n\n";
                
                $logContent .= "=== İŞLEM BAŞARILI BİTTİ - " . date("Y-m-d H:i:s") . " ===\n";
                
                // Log dosyasına yazma
                file_put_contents($logFilePath, $logContent);
                
                return $returnData;
            }
            
        } catch (Exception $e) {
            $logContent .= "HATA YAKALANDI: " . $e->getMessage() . "\n";
            $logContent .= "Dosya: " . $e->getFile() . "\n";
            $logContent .= "Satır: " . $e->getLine() . "\n";
            $logContent .= "Trace: " . $e->getTraceAsString() . "\n";
            
            // Log dosyasına yazma
            file_put_contents($logFilePath, $logContent);
            
            return ['error' => $e->getMessage(), 'log_file' => $logFilePath];
        }
    }

    public static function havalegonder($model){
        $tahsilatUrl = self::getDiaUrl('scf');
        $dateOnly = date('Y-m-d');
        $ssid=Dia::getsessionid();

        if($model->FisId==null)
            $fisid=$model->HareketId;
        else 
            $fisid=$model->FisId;
        $tarih=date("Y-m-d");
        $saat=date("H:i:s");
        $data = <<<EOT
            {"bcs_banka_fisi_ekle" :
                {"session_id": "$ssid",
                "firma_kodu": 1,
                "donem_kodu": 1,
                "kart": 
                    {
                    "_key_sis_ozelkod": 0,
                    "_key_sis_seviyekodu": 0,
                    "_key_sis_sube_source": {"subekodu": "44.03"},
                    "aciklama1": "GELEN HAVALE",
                    "aciklama2": "",
                    "aciklama3": "",
                    "fisno": $fisid,
                    "m_kalemler": [{"_key_bcs_banka_kredi_taksit": 0,
                                            "_key_bcs_bankahesabi": 5374478,
                                            "_key_muh_masrafmerkezi": 0,
                                            "_key_prj_proje": 0,
                                            "_key_scf_cari": {"carikartkodu": "$model->carikod"},
                                            "_key_scf_carikart_banka": 0,
                                            "_key_sis_ozelkod": 0,
                                            "aciklama": "GELEN HAVALE",
                                            "_key_sis_doviz": {"adi": "GBP"},
                                            "_key_sis_doviz_raporlama": {"adi": "GBP"},
                                            "belgeno": "",
                                            "borc_cari": "$model->Tutar,",
                                            "detay": "CHSP",
                                            "dovizkuru": "1.00",
                                            "kurfarkiborc": "0.00",
                                            "raporlamadovizkuru": "1.00"}],
                    "odemeturu": "A",
                    "saat": "$saat",
                    "tarih": "$tarih",
                    "turu": "GEHVL"
                    }
                }
            }

            EOT;

            $curl = curl_init();
            curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
            curl_setopt($curl, CURLOPT_POSTFIELDS, $data);
            curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($curl, CURLOPT_HTTPHEADER, array(
                'Content-Type: application/json',
                'Content-Length: ' . strlen($data))
            );
            curl_setopt($curl, CURLOPT_URL, $url);
            $result = curl_exec($curl);

            $json=json_decode($result,true);
            curl_close($curl);
    }

    public static function tahsilatgonder($model){
        // Log başlangıcı
        $logMessage = "=== DIA::tahsilatgonder BAŞLADI ===\n";
        $logMessage .= "Tarih: " . date('Y-m-d H:i:s') . "\n";
        $logMessage .= "Model ID: " . $model->HareketId . "\n";
        $logMessage .= "FisId: " . $model->FisId . "\n";
        $logMessage .= "Tutar: " . $model->Tutar . "\n";
        $logMessage .= "OdemeYontemi: " . $model->OdemeYontemi . "\n";
        $logMessage .= "CariKod: " . $model->carikod . "\n";
        $logMessage .= "Aciklama: " . $model->Aciklama . "\n";
        
        $tahsilatUrl = self::getDiaUrl('scf');
        $logMessage .= "DIA URL: " . $tahsilatUrl . "\n";
        
        $dateOnly = date('Y-m-d');
        $ssid = Dia::getsessionid();
        $logMessage .= "Session ID: " . $ssid . "\n";
        
        // Gönderilecek veri
        $tur = null;
        $aciklama = null;
        $bankaKey = null; // Sadece KK'da kullanılacak

        if ($model->OdemeYontemi == "Nakit") {
            $tur = "NT";
            $aciklama = "Nakit Tahsilat";
            // Nakit için banka hesabı göndermiyoruz
        } elseif ($model->OdemeYontemi == "Kredi Kartı") {
            $tur = "KK";
            $aciklama = "Kredi Kartı Tahsilat";
            $bankaKey = Yii::$app->params['dia_banka_key'];
        } else {
            // Bilinmeyen ödeme yöntemi (ileride Çek vs. gelirse buraya düşer)
            $logMessage .= "Bilinmeyen OdemeYontemi: " . $model->OdemeYontemi . "\n";
            file_put_contents(\Yii::getAlias('@runtime/dia_tahsilat_log.txt'), $logMessage, FILE_APPEND | LOCK_EX);
            return json_encode([
                'success' => false,
                'message' => 'Bilinmeyen ödeme yöntemi: ' . (string)$model->OdemeYontemi,
            ], JSON_UNESCAPED_UNICODE);
        }

        $logMessage .= "Ödeme Türü: " . $tur . "\n";
        $logMessage .= "BankaKey: " . ($bankaKey !== null ? $bankaKey : 'YOK') . "\n";
        
        Yii::$app->response->format = \yii\web\Response::FORMAT_JSON;

        // fisno (DIA için tekil belge numarası) -> Virgül içeriyorsa (çoklu fiş) HareketId kullan
        $fisno = $model->HareketId;
        if (!empty($model->FisId) && strpos((string)$model->FisId, ',') === false) {
            $fisno = $model->FisId;
        }
        $logMessage .= "Kullanılan fisno: " . $fisno . "\n";
        
        // Kalem (bankahesap sadece KK'da gönderilecek)
        $kalem = [
            "_key_scf_carikart" => ["carikartkodu" => $model->carikod],
            "_key_sis_doviz" => ["adi" => "GBP"],
            "_key_sis_doviz_raporlama" => ["adi" => "GBP"],
            "aciklama" => "",
            "alacak" => $model->Tutar,
            "dovizkuru" => "1.00",
            "kurfarkialacak" => "0.00",
            "kurfarkiborc" => "0.00",
            "makbuzno" => "",
            "carikart" => "",
            "cariunvan" => "",
            "raporlamadovizkuru" => "1.00",
            "vade" => date('Y-m-d'),
        ];
        if ($tur === 'KK' && !empty($bankaKey)) {
            $kalem["_key_bcs_bankahesabi"] = is_numeric($bankaKey) ? (int)$bankaKey : $bankaKey;
        }

        $data = [
            "scf_carihesap_fisi_ekle" => [
                "session_id" => $ssid,
                "firma_kodu" => 1,
                "donem_kodu" => 1,
                "kart" => [
                    "_key_sis_sube" => ["subekodu" => "44.01"],
                    "aciklama1" => $aciklama,
                    "aciklama2" => $model->Aciklama,
                    "aciklama3" => "",
                    "belgeno" => $model->HareketId,
                    "fisno" => $fisno,
                    "m_kalemler" => [
                        $kalem
                    ],
                    "saat" => date('H:i:s'),
                    "tarih" => date('Y-m-d'),
                    "turu" => $tur
                ]
            ]
        ];

        $jsonData = json_encode($data);
        $logMessage .= "JSON Data: " . $jsonData . "\n";
        $logMessage .= "JSON Data Length: " . strlen($jsonData) . "\n";
        
        // cURL başlat
        $curl = curl_init();
        curl_setopt($curl, CURLOPT_URL, $tahsilatUrl);
        curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($curl, CURLOPT_POSTFIELDS, $jsonData);
        curl_setopt($curl, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'Content-Length: ' . strlen($jsonData)
        ]);
        curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($curl, CURLOPT_TIMEOUT, 120); // 2 dakika toplam işlem süresi
        curl_setopt($curl, CURLOPT_CONNECTTIMEOUT, 30); // 30 saniye bağlantı zaman aşımı
        
        $logMessage .= "cURL seçenekleri ayarlandı\n";
        $logMessage .= "cURL URL: " . $tahsilatUrl . "\n";
        $logMessage .= "cURL Method: POST\n";
        $logMessage .= "cURL Headers: Content-Type: application/json, Content-Length: " . strlen($jsonData) . "\n";

        $result = curl_exec($curl);
        $httpCode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
        $curlError = curl_error($curl);
        $curlErrno = curl_errno($curl);
        
        $logMessage .= "cURL HTTP Code: " . $httpCode . "\n";
        $logMessage .= "cURL Error No: " . $curlErrno . "\n";
        $logMessage .= "cURL Error: " . $curlError . "\n";
        $logMessage .= "cURL Response: " . $result . "\n";

        // Eğer cURL hatası varsa txt dosyasına yazdır
        if (curl_errno($curl)) {
            $hataMesaji = 'cURL hatası: ' . curl_error($curl) . ' - ' . date('Y-m-d H:i:s') . PHP_EOL;
            file_put_contents(\Yii::getAlias('@runtime/curl_hatalari.txt'), $hataMesaji, FILE_APPEND | LOCK_EX);
            $logMessage .= "cURL hatası tespit edildi ve curl_hatalari.txt'ye yazıldı\n";
        } else {
            // Sonuç
            $json = json_decode($result, true);
            $logMessage .= "JSON decode başarılı: " . (is_array($json) ? 'Evet' : 'Hayır') . "\n";
            if (is_array($json)) {
                $logMessage .= "JSON Response: " . print_r($json, true) . "\n";
            }
        }

        curl_close($curl);
        $logMessage .= "cURL kapatıldı\n";
        $logMessage .= "=== DIA::tahsilatgonder TAMAMLANDI ===\n\n";
        
        // Log dosyasına yaz
        file_put_contents(\Yii::getAlias('@runtime/dia_tahsilat_log.txt'), $logMessage, FILE_APPEND | LOCK_EX);
        
        return $result;
    }
    public static function cekiletahsilatgonder($model){
        // Log başlangıcı
        $logMessage = "=== DIA::tahsilatgonder BAŞLADI ===\n";
        $logMessage .= "Tarih: " . date('Y-m-d H:i:s') . "\n";
        $logMessage .= "Model ID: " . $model->HareketId . "\n";
        $logMessage .= "FisId: " . $model->FisId . "\n";
        $logMessage .= "Tutar: " . $model->Tutar . "\n";
        $logMessage .= "OdemeYontemi: " . $model->OdemeYontemi . "\n";
        $logMessage .= "CariKod: " . $model->carikod . "\n";
        $logMessage .= "Aciklama: " . $model->Aciklama . "\n"; 
        
        $tahsilatUrl = self::getDiaUrl('bcs');
        $logMessage .= "DIA URL: " . $tahsilatUrl . "\n";
        
        $dateOnly = date('Y-m-d');
        $ssid = Dia::getsessionid();
        $logMessage .= "Session ID: " . $ssid . "\n";
        
        Yii::$app->response->format = \yii\web\Response::FORMAT_JSON;

        // fisno (DIA için tekil belge numarası) -> Virgül içeriyorsa (çoklu fiş) HareketId kullan
        $fisno = $model->HareketId;
        if (!empty($model->FisId) && strpos((string)$model->FisId, ',') === false) {
            $fisno = $model->FisId;
        }
        $logMessage .= "Kullanılan fisno: " . $fisno . "\n";
        $subeKodu= Yii::$app->guser->identity->branch_code;
        $sube= Branches::find()->where(["branch_code"=>$subeKodu])->one();
        $bankaKey = is_numeric(Yii::$app->params['dia_banka_key']) ? (int)Yii::$app->params['dia_banka_key'] : Yii::$app->params['dia_banka_key'];
        file_put_contents(\Yii::getAlias('@runtime/dia_tahsilat_log.txt'), $logMessage, FILE_APPEND | LOCK_EX);
        $logMessage="";
        /*
        $data = [
            "bcs_cs_bordro_ekle" => [
                "session_id" => $ssid,
                "firma_kodu" => 1,
                "donem_kodu" => 1,
                "kart" => [
                    "_key_sis_sube" => $sube->_key,
                    "aciklama1" => "Çek ile Ödeme",
                    "aciklama2" => $model->Aciklama,
                    "aciklama3" => "",
                    "bordrono" => $model->HareketId,
                    "bordrotarihi" => date('Y-m-d'),
                    "raporlamadovizkuru" => "1.00",
                    "saat" => date('H:i:s'),
                    "teminatdurumu" => "H",
                    "belgeturu" =>2,
                    "turu" => "CG",
                    "m_ceksenet" => [
                        [
                            "_key_bcs_bankahesabi" =>  5374478,
                            "_key_muh_masrafmerkezi" => 0,
                            "_key_muh_masrafmerkezi_donemsiz" => 0,
                            "_key_prj_proje" => 0,
                            "_key_scf_carikart" => 0,
                            "_key_scf_malzeme_baglantisi" => 0,
                            "_key_sis_doviz" => ["adi" => "GBP"],
                            "_key_sis_ozelkod" => 0,
                            "_key_sis_seviyekodu" => 0,
                            "aciklama" => $model->Aciklama,
                            "bankaadi" => "",
                            "borclu" => $model->carikod,
                            "cirolu" => "H",
                            "hesapno" => "",
                            "iban" => "",
                            "kefil" => "",
                            "kefil2" => "",
                            "kefil2bilgi" => "",
                            "kefilbilgi" => "",
                            "muhabirsube" => "",
                            "odemeyeri" => "",
                            "subekodu" => $subeKodu,
                            "tutar" => $model->Tutar,
                            "tutar_cari" => $model->Tutar,
                            "vade" => $model->vadetarihi,
                            
                        ]
                    ]
                ]
            ]
        ];
        */

        $key=$model->cari->_key;
        $borclu=$model->cari->Unvan;
        $tutar=$model->Tutar;
        $tarih=$model->HareketTarihi;
        $vadeTarihi = !empty($model->vadetarihi) ? (string)$model->vadetarihi : date('Y-m-d');
        // Banka hesabını DİA'nın beklediği şekilde referansla: öncelik hesapkodu, aksi halde _key
        $bankaHesapKodu = Yii::$app->params['dia_banka_hesapkodu'] ?? null;
        if (!empty($bankaHesapKodu)) {
            $bankahesapRef = ["hesapkodu" => (string)$bankaHesapKodu];
        } elseif (!empty($bankaKey)) {
            $bankahesapRef = ["_key" => (int)$bankaKey];
        } else {
            $bankahesapRef = 0;
        }
        // Geçerli JSON üretimi: PHP array -> json_encode
        $data = [
            "bcs_cs_bordro_ekle" => [
                "session_id" => $ssid,
                "firma_kodu" => 1,
                "donem_kodu" => 1,
                "kart" => [
                    "_key_kodu"=> $key,
                    "_key_sis_sube" => $sube ? $sube->_key : 0,
                    "aciklama1" => "Çek ile Tahsilat",
                    "aciklama2" => (string)$model->Aciklama,
                    "aciklama3" => "",
                    "bordrono" => (string)$model->HareketId,
                    "bordrotarihi" => date('Y-m-d'),
                    "raporlamadovizkuru" => "1.00",
                    "saat" => date('H:i:s'),
                    "teminatdurumu" => "H",
                    "belgeturu" => 2,
                    "turu" => "CG",
                    "m_ceksenet" => [
                        [
                            "_key_bcs_bankahesabi" => $bankahesapRef,
                            "_key_muh_masrafmerkezi" => 0,
                            "_key_muh_masrafmerkezi_donemsiz" => 0,
                            "_key_prj_proje" => 0,
                            "_key_scf_carikart" => 0,
                            "_key_scf_malzeme_baglantisi" => 0,
                            "_key_sis_doviz" => ["adi" => "GBP"],
                            "_key_sis_ozelkod" => 0,
                            "_key_sis_seviyekodu" => 0,
                            "_key_sis_doviz_cari"=> 2303,
                            "dovizkuru"=> "1.000000",
                            "dovizkuru_iliski"=> "1.000000",
                            "aciklama" => (string)$model->Aciklama,
                            "bankaadi" => "",
                            "borclu" => (string)$model->carikod,
                            "cirolu" => "H",
                            "hesapno" => "",
                            "iban" => "",
                            "kefil" => "",
                            "kefil2" => "",
                            "kefil2bilgi" => "",
                            "kefilbilgi" => "",
                            "muhabirsube" => "",
                            "odemeyeri" => "",
                            "subekodu" => (string)$subeKodu,
                            "tutar" => (string)$model->Tutar,
                            "tutar_cari" => (string)$model->Tutar,
                            "vade" => $vadeTarihi,
                            "valor" => $vadeTarihi,
                            "turu" => "CEK_MST"
                        ]
                    ]
                ]
            ]
        ];
        $jsonData = json_encode($data, JSON_UNESCAPED_UNICODE);
        
        $logMessage .= "JSON Data: " . $jsonData . "\n";
        $logMessage .= "JSON Data Length: " . strlen($jsonData) . "\n";
        
        // cURL başlat
        $curl = curl_init();
        curl_setopt($curl, CURLOPT_URL, $tahsilatUrl);
        curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($curl, CURLOPT_POSTFIELDS, $jsonData);
        curl_setopt($curl, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'Content-Length: ' . strlen($jsonData)
        ]);
        curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($curl, CURLOPT_TIMEOUT, 120); // 2 dakika toplam işlem süresi
        curl_setopt($curl, CURLOPT_CONNECTTIMEOUT, 30); // 30 saniye bağlantı zaman aşımı
        
        $logMessage .= "cURL seçenekleri ayarlandı\n";
        $logMessage .= "cURL URL: " . $tahsilatUrl . "\n";
        $logMessage .= "cURL Method: POST\n";
        $logMessage .= "cURL Headers: Content-Type: application/json, Content-Length: " . strlen($jsonData) . "\n";

        $result = curl_exec($curl);
        $httpCode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
        $curlError = curl_error($curl);
        $curlErrno = curl_errno($curl);
        
        $logMessage .= "cURL HTTP Code: " . $httpCode . "\n";
        $logMessage .= "cURL Error No: " . $curlErrno . "\n";
        $logMessage .= "cURL Error: " . $curlError . "\n";
        $logMessage .= "cURL Response: " . $result . "\n";

        // Eğer cURL hatası varsa txt dosyasına yazdır
        if (curl_errno($curl)) {
            $hataMesaji = 'cURL hatası: ' . curl_error($curl) . ' - ' . date('Y-m-d H:i:s') . PHP_EOL;
            file_put_contents(\Yii::getAlias('@runtime/curl_hatalari.txt'), $hataMesaji, FILE_APPEND | LOCK_EX);
            $logMessage .= "cURL hatası tespit edildi ve curl_hatalari.txt'ye yazıldı\n";
        } else {
            // Sonuç
            $json = json_decode($result, true);
            $logMessage .= "JSON decode başarılı: " . (is_array($json) ? 'Evet' : 'Hayır') . "\n";
            if (is_array($json)) {
                $logMessage .= "JSON Response: " . print_r($json, true) . "\n";
            }
        }

        curl_close($curl);
        $logMessage .= "cURL kapatıldı\n";
        $logMessage .= "=== DIA::tahsilatgonder TAMAMLANDI ===\n\n";
        
        // Log dosyasına yaz
        file_put_contents(\Yii::getAlias('@runtime/dia_tahsilat_log.txt'), $logMessage, FILE_APPEND | LOCK_EX);
        
        return $result;
    }

    public static function iadegonder($model){
        $tahsilatUrl = self::getDiaUrl('scf');
        $dateOnly = date('Y-m-d');
        $ssid=Dia::getsessionid();
        // Gönderilecek veri

        if( $model->tur=="cash"){
            $tur="NÖ";
            $aciklama="Cash refund";
            $banka=0;
        }
        else if($model->tur=="credit"){
            $tur="KI";
            $aciklama="Kredi Kartı ile Iade";
            $banka=Yii::$app->params['dia_banka_key'];
        }
        else if($model->tur=="check"){
            $tur="ÇÖ";
            $aciklama="Çek ile Iade";
            $banka=0;
        }
        Yii::$app->response->format = \yii\web\Response::FORMAT_JSON;
        $fisid = $model->FisId;
        $data = [
            "scf_carihesap_fisi_ekle" => [
                "session_id" => $ssid,
                "firma_kodu" => 1,
                "donem_kodu" => 1,
                "kart" => [
                    "_key_sis_sube" => ["subekodu" => "44.01"],
                    "aciklama1" => $aciklama,
                    "aciklama2" => $model->aciklama,
                    "aciklama3" => "",
                    "belgeno" => $model->FisId,
                    "fisno" => $fisid,
                    "m_kalemler" => [
                        [
                            "_key_bcs_bankahesabi"=> $banka,
                            "_key_scf_carikart" => ["carikartkodu" => $model->MusteriId],
                            "_key_sis_doviz" => ["adi" => "GBP"],
                            "_key_sis_doviz_raporlama" => ["adi" => "GBP"],
                            "aciklama" => "",
                            "alacak" => $model->Toplamtutar,
                            "dovizkuru" => "1.00",
                            "kurfarkialacak" => "0.00",
                            "kurfarkiborc" => "0.00",
                            "makbuzno" => "",
                            "carikart" => "",
                            "cariunvan" => "",
                            "raporlamadovizkuru" => "1.00",
                            "vade" => date('Y-m-d'),
                        ]
                    ],
                    "saat" => date('H:i:s'),
                    "tarih" => date('Y-m-d'),
                    "turu" => $tur
                ]
            ]
        ];

        $jsonData = json_encode($data);
        // cURL başlat
        $curl = curl_init();
        curl_setopt($curl, CURLOPT_URL, $tahsilatUrl);
        curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($curl, CURLOPT_POSTFIELDS, $jsonData);
        curl_setopt($curl, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'Content-Length: ' . strlen($jsonData)
        ]);

        curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);

        $result = curl_exec($curl);

        // Eğer cURL hatası varsa log'a yaz
        if (curl_errno($curl)) {
            \Yii::error('Dia iadegonder cURL hatası: ' . curl_error($curl));
        } else {
            // Sonuç
            $json = json_decode($result, true);
            \Yii::info('Dia iadegonder API Response: ' . print_r($json, true));
        }

        curl_close($curl);
    }

    public static function numarailefisgonder($fisno){
        $tahsilatUrl = self::getDiaUrl('scf');
        $dateOnly = date('Y-m-d');
        $ssid=Dia::getsessionid();
        $fis=Satisfisleri::find()->where(["FisNo"=>$fisno])->one();
        $satirlar=$fis->satissatirlari;
        $kalemler=[];
        $sira=1;
        foreach ($satirlar as $satir) {
            $sd=[];
            $stok=Urunler::find()->where(["Stokkodu"=>$satir->StokKodu])->one();
            if($satir->BirimTipi=="UNIT")
                $birimkey=$stok->BirimKey1;
            else
                $birimkey=$stok->BirimKey2;
            $indirim=0;
            if($satir->Iskonto>0)
                $indirim=round((($satir->BirimFiyti*$satir->Miktar)*$satir->Iskonto/100),2);
            $satirtutari=$satir->BirimFiyat*$satir->Miktar*(1-$satir->Iskonto/100);
            $satirkdv=$satirtutari*$satir->vat/100;
            $sd=[
                "_key_kalemturu" => ["stokkartkodu" => $satir->StokKodu],
                "_key_scf_kalem_birimleri" => $birimkey,
                "_key_sis_depo_source" => ["depokodu" => "44.03.01"],
                "_key_sis_doviz" => ["adi" => "GBP"],
                "anamiktar" => $satir->Miktar,
                "birimfiyati" => $satir->BirimFiyat,
                "dovizkuru" => "1.000000",
                "irstarih" => $fis->Fistarihi,
                "kalemturu" => "MLZM",
                "kdv" => $stok->Vat,
                "kdvdurumu" => "H",
                "indirim1"=>$indirim,
                "kdvtutari" => $satirkdv,
                "miktar" =>  $satir->Miktar,
                "sirano" => $sira,
                "sonbirimfiyati" =>$satir->BirimFiyat,
                "tutari" => $satirtutari,
                "yerelbirimfiyati" =>$satir->BirimFiyat,
                "m_varyantlar" => []
            ];
            $kalemler[]=$sd;
            $sira++;
        }
   
        $data = [
            "scf_fatura_ekle" => [
                "session_id" => $ssid,
                "firma_kodu" => 1,
                "donem_kodu" => 1,
                "kart" => [
                    "_key_scf_carikart" => ["carikartkodu" =>$fis->musteri->Kod],
                    "_key_scf_odeme_plani" => ["kodu" => "00000001"],
                    "_key_sis_depo_source" => ["depokodu" => $fis->kasa->depokodu??"44.03.01"],
                    "_key_sis_doviz" => ["adi" => "GBP"],
                    "_key_sis_doviz_raporlama" => ["adi" => "GBP"],
                    "_key_sis_sube_source" => ["subekodu" => $fis->kasa->subeodu??"44.03"],
                    "aciklama1" => "musteriid: ",
                    "aciklama2" => "fisno: ",
                    "belgeno" =>  $fis->FisNo,
                    "fisno" => $fis->FisNo,
                    "karsifirma" => "C",
                    "kasafisno" => $fis->FisNo,
                    "dovizkuru" => "1.000000",
                    "kategori" => "F",
                    "m_kalemler" => $kalemler,
                    "raporlamadovizkuru" => "1.000000",
                    "saat" => "14:55:53",
                    "sevkadresi1" => "YILDIRIMÖNÜ MAH. ÇAMDALI SOK. NO:118",
                    "sevkadresi2" => "",
                    "sevkadresi3" => "Keçiören ANKARA",
                    "tarih" => $dateOnly,
                    "turu" => 2
                ]
            ]
        ];
        
        $jsonData = json_encode($data);
       // echo $jsonData;
        // cURL başlat
        $curl = curl_init();
        curl_setopt($curl, CURLOPT_URL,  $tahsilatUrl); // Burada $newUrl kullanıyoruz
        curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($curl, CURLOPT_POSTFIELDS, $jsonData);
        curl_setopt($curl, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'Content-Length: ' . strlen($jsonData)
        ]);
        
        curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false); // Sertifika doğrulamasını kapatıyoruz (test amaçlı)
        
        $result = curl_exec($curl);
        
        // Eğer cURL hatası varsa yazdır
        if (curl_errno($curl)) {
            $hataMesaji = 'cURL hatası: ' . curl_error($curl) . ' - ' . date('Y-m-d H:i:s') . PHP_EOL;
            file_put_contents('runtime/curl_hatalari.txt', $hataMesaji, FILE_APPEND | LOCK_EX);
           $sonuc=0;
        } else {
            $sonuc=1;
            // Sonuç
            //
             $json = json_decode($result, true);
             $fis->diakey=$json["key"];
             if(!$fis->save()){
                echo "<pre>";
                print_r(json_encode($fis->errors)); // API'nin dönüşünü yazdır
                echo "</pre>";
             }
             return 0;

        }  
        curl_close($curl);
         return $sonuc; 
    }
    public static function fisgonder($fis,$tur){
        $tahsilatUrl = self::getDiaUrl('scf');
        $dateOnly = date('Y-m-d');
        $ssid=Dia::getsessionid();
        if($tur==2)
            $satirlar=Satissatirlari::find()->where(["FisNo"=>$fis->FisNo])->all();
        else if($tur==7)
            $satirlar=Iadesatirlari::find()->where(["FisNo"=>$fis->FisNo])->all();

        $kalemler=[];
        $sira=1;
            
        foreach ($satirlar as $satir) {
            $sd=[];
            if($satir->ToplamTutar>0.01){
                $stok=Urunler::find()->where(["StokKodu"=>$satir->StokKodu])->one();
                if($satir->BirimTipi=="UNIT")
                    $birimkey=$stok->BirimKey1;
                else
                    $birimkey=$stok->BirimKey2;

                $satirtutari=$satir->BirimFiyat*$satir->Miktar*(1-$satir->Iskonto/100);
                $satirkdv=$satirtutari*$satir->vat/100;
                $sd=[
                    "_key_kalemturu" => ["stokkartkodu" => $satir->StokKodu],
                    "_key_scf_kalem_birimleri" => $birimkey,
                    "_key_sis_depo_source" => ["depokodu" => "44.01.01"],
                    "_key_sis_doviz" => ["adi" => "GBP"],
                    "anamiktar" => $satir->Miktar,
                    "birimfiyati" => $satir->BirimFiyat,
                    "dovizkuru" => "1.000000",
                    "irstarih" => $fis->Fistarihi,
                    "kalemturu" => "MLZM",
                    "kdv" => $stok->Vat,
                    "kdvdurumu" => "H",
                    "indirim1"=> $satir->Iskonto,
                    "kdvtutari" => $satirkdv,
                    "miktar" =>  $satir->Miktar,
                    "sirano" => $sira,
                    "sonbirimfiyati" =>$satir->BirimFiyat,
                    "tutari" => $satirtutari,
                    "yerelbirimfiyati" =>$satir->BirimFiyat,
                    "m_varyantlar" => []
                ];
                $kalemler[]=$sd;
                $sira++;
            }
        }
   
            if($tur==2){
                $iskonto=$fis->Iskontotutari;
            }
            else $iskonto=0;

        if($iskonto>0){
            $alt=[
                "turu"=>"GTD",
                "deger"=>$fis->Iskontotutari,
                "tutar"=>$fis->Iskontotutari,
                "kalemturu"=>"INDR",
                "_key_sis_doviz"=>["adi" => "GBP"],
                "dovizkuru"=>1
            ];
        }
        else 
            $alt=null;

        $data = [
            "scf_fatura_ekle" => [
                "session_id" => $ssid,
                "firma_kodu" => 1,
                "donem_kodu" => 1,
                "kart" => [
                    "_key_scf_carikart" => ["carikartkodu" =>$fis->MusteriId],
                    "_key_sis_depo_source" => ["depokodu" => $fis->kasa->depokodu??"44.03.01"],
                    "_key_sis_doviz" => ["adi" => "GBP"],
                    "_key_sis_doviz_raporlama" => ["adi" => "GBP"],
                    "_key_sis_sube_source" => ["subekodu" => "44.03"],
                    "aciklama1" => "musteriid: ",
                    "aciklama2" => "fisno: ",
                    "belgeno" =>  $fis->FisNo,
                    "belgeno2" =>  $fis->FisNo,
                    "fisno" => $fis->FisNo,
                    "karsifirma" => "C",
                    "kasafisno" => $fis->FisNo,
                    "dovizkuru" => "1.000000",
                    "kategori" => "F",
                    "m_kalemler" => $kalemler,
                    "raporlamadovizkuru" => "1.000000",
                    "saat" => date('H:i:s'),
                    "sevkadresi1" => "",
                    "sevkadresi2" => "",
                    "sevkadresi3" => "",
                    "tarih" => $dateOnly,
                    "turu" => $tur,
                    "toplamindirim"=>$iskonto,
                    "toplamindirimdvz"=>$iskonto,
                    "ekalan5" =>  $fis->tillname //$fis->satispersoneli,
                ]
            ]
        ];

        if($iskonto > 0){
            $alt = [
                "turu"=>"NT",
                "deger"=>$fis->Iskontotutari,
                "tutar"=>$fis->Iskontotutari,
                "kalemturu"=>"INDR",
                "_key_sis_doviz"=>["adi" => "GBP"],
                "dovizkuru"=>1
            ];
            $data['scf_fatura_ekle']['kart']['m_altlar'] = [$alt];
        }
        
        $jsonData = json_encode($data);
        // echo $jsonData;
        // cURL başlat

        $curl = curl_init();
        curl_setopt($curl, CURLOPT_URL,  $tahsilatUrl); // Burada $newUrl kullanıyoruz
        curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($curl, CURLOPT_POSTFIELDS, $jsonData);
        curl_setopt($curl, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'Content-Length: ' . strlen($jsonData)
        ]);
        
        curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false); // Sertifika doğrulamasını kapatıyoruz (test amaçlı)
        
        $result = curl_exec($curl);
        
        // Eğer cURL hatası varsa yazdır
        if (curl_errno($curl)) {
            $hataMesaji = 'cURL hatası: ' . curl_error($curl) . ' - ' . date('Y-m-d H:i:s') . PHP_EOL;
            file_put_contents('runtime/curl_hatalari.txt', $hataMesaji, FILE_APPEND | LOCK_EX);
           $sonuc=["code"=>0,"hata"=>$hataMesaji];
        } else {
             $json = json_decode($result, true);
              echo json_encode($json);
     
             if($json["code"]==200){
                if($json["key"]){
                    $fis->diakey=$json["key"];
                    if(!$fis->save()){
                        echo "<pre>";
                        print_r(json_encode($fis->errors)); // API'nin dönüşünü yazdır
                        echo "</pre>";
                    }
                 }
                 $sonuc= $json;
             } 
             else 
             $sonuc= $json;
        }   
        curl_close($curl);
        return $sonuc; 
    }
    

    public static function gunlukfaturagetir($faturano){
        $url = self::getDiaUrl('rpr');
        $session_id = Dia::getsessionid();
        $firma_kodu = 1;
        $donem_kodu = 1;

        $data = [
            "rpr_raporsonuc_getir" => [
                "session_id" => $session_id,
                "firma_kodu" => 1,
                "donem_kodu" => 1,
                "report_code" => "scf2201c",
                "tasarim_key" => 1200,
                "param" => [
                    "_key" => "faturano:".$faturano,
                ],
                "format_type" => "pdf"
            ]
        ];
        $jsonData = json_encode($data);
        $curl = curl_init();
        curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
        curl_setopt($curl, CURLOPT_POSTFIELDS, $jsonData);
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($curl, CURLOPT_HTTPHEADER, array(
            'Content-Type: application/json',
            'Content-Length: ' . strlen($jsonData))
        );
        curl_setopt($curl, CURLOPT_URL, $url);
        $result = curl_exec($curl);

        $json=json_decode($result,true);
        curl_close($curl);
        print_r($json);
    }

    public static function faturapdfgetir($keyno){
        
        $url = self::getDiaUrl('rpr');
        $session_id = Dia::getsessionid();
        $firma_kodu = 1;
        $donem_kodu = 1;

        $data =  [
            "rpr_raporsonuc_getir" => [
                "session_id" => $session_id,
                "firma_kodu" => 1,
                "donem_kodu" => 1,
                "report_code" => "scf2201c",
                "tasarim_key" => 3873238,
                "param" => [ "_key" => $keyno ],
                "format_type" => "pdf"
            ]
        ];
        $jsonData = json_encode($data);
        
            $curl = curl_init();
            curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
            curl_setopt($curl, CURLOPT_POSTFIELDS, $jsonData);
            curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
            // curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);
            // curl_setopt($curl, CURLOPT_SSL_VERIFYHOST, 0);
            curl_setopt($curl, CURLOPT_HTTPHEADER, array(
                'Content-Type: application/json',
                'Content-Length: ' . strlen($jsonData))
            );
      
             curl_setopt($curl, CURLOPT_URL, $url);
             $result = curl_exec($curl);
            if (curl_errno($curl)) {
                $hataMesaji = 'cURL hatası: ' . curl_error($curl) . ' - ' . date('Y-m-d H:i:s') . PHP_EOL;
            file_put_contents('runtime/curl_hatalari.txt', $hataMesaji, FILE_APPEND | LOCK_EX);
            } 
            else {
                // Sonuç
                // $json = json_decode($result, true);
                // echo "<pre>";
                // print_r($json); // API'nin dönüşünü yazdır
                // echo "</pre>";
            }
    
             curl_close($curl);

        
        // $json=json_decode($result,true);
        // curl_close($curl);
        // print_r($json);
        
        //$pdfContent = base64_decode($json['result']);
        //echo $result["result"];
        // // PDF'in geçerli olup olmadığını kontrol etme
        // if (strpos($pdfContent, '%PDF') !== 0) {
        //     throw new \yii\web\HttpException(400, 'Geçersiz PDF dosyası');
        // }
        
        // // Yanıtı PDF olarak gönderme
        // \Yii::$app->response->format = Response::FORMAT_RAW;
        // \Yii::$app->response->headers->add('Content-Type', 'application/pdf');
        // \Yii::$app->response->headers->add('Content-Disposition', 'attachment; filename="belge.pdf"');
        
        //return $pdfContent;
    }
    

    public static function iadefaturapdfgetir($keyno){
        $url = self::getDiaUrl('rpr');
        $session_id = Dia::getsessionid();
        $firma_kodu = 1;
        $donem_kodu = 1;

        $data =  [
            "rpr_raporsonuc_getir" => [
                "session_id" => $session_id,
                "firma_kodu" => 1,
                "donem_kodu" => 1,
                "report_code" => "scf2201c",
                "tasarim_key" => 5374460,
                "param" => [ "_key" => $keyno ],
                "format_type" => "pdf"
            ]
        ];
        $jsonData = json_encode($data);
        
            $curl = curl_init();
            curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
            curl_setopt($curl, CURLOPT_POSTFIELDS, $jsonData);
            curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
            // curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);
            // curl_setopt($curl, CURLOPT_SSL_VERIFYHOST, 0);
            curl_setopt($curl, CURLOPT_HTTPHEADER, array(
                'Content-Type: application/json',
                'Content-Length: ' . strlen($jsonData))
            );
      
             curl_setopt($curl, CURLOPT_URL, $url);
             $result = curl_exec($curl);
            if (curl_errno($curl)) {
                $hataMesaji = 'cURL hatası: ' . curl_error($curl) . ' - ' . date('Y-m-d H:i:s') . PHP_EOL;
            file_put_contents('runtime/curl_hatalari.txt', $hataMesaji, FILE_APPEND | LOCK_EX);
            } 
            else {
                // Sonuç
                // $json = json_decode($result, true);
                // echo "<pre>";
                // print_r($json); // API'nin dönüşünü yazdır
                // echo "</pre>";
            }
    
             curl_close($curl);

        
        // $json=json_decode($result,true);
        // curl_close($curl);
        // print_r($json);
        
        //$pdfContent = base64_decode($json['result']);
        //echo $result["result"];
        // // PDF'in geçerli olup olmadığını kontrol etme
        // if (strpos($pdfContent, '%PDF') !== 0) {
        //     throw new \yii\web\HttpException(400, 'Geçersiz PDF dosyası');
        // }
        
        // // Yanıtı PDF olarak gönderme
        // \Yii::$app->response->format = Response::FORMAT_RAW;
        // \Yii::$app->response->headers->add('Content-Type', 'application/pdf');
        // \Yii::$app->response->headers->add('Content-Disposition', 'attachment; filename="belge.pdf"');
        
        //return $pdfContent;
    }  
    public static function siparisgondermobil($fis, $tur = 1, $logFilePath = null)
    {
        ini_set('memory_limit', '512M');
        ini_set('max_execution_time', 300);
        // ini_set('zlib.output_compression', 0);
        // ini_set('output_buffering', 'off');
        // while (ob_get_level()) {
        //     ob_end_clean();
        // }
        
       // Yii::$app->response->format = \yii\web\Response::FORMAT_RAW;
        //Yii::$app->response->headers->set('Content-Type', 'text/plain; charset=UTF-8');
     
        $logFilePath = Yii::getAlias('@app/runtime/mobilsiparis_'.date("ymdhis").'.txt');

        $logAction = function($message) use ($logFilePath) {
            if ($logFilePath) {
                file_put_contents($logFilePath, date('[Y-m-d H:i:s] ') . $message . "\n", FILE_APPEND);
            }
        };

        $logAction("--- siparisgondermobil LOG BAŞLANGIÇ ---");
        $logAction("Fiş No: {$fis->FisNo}, Tür: $tur");

        $url = self::getDiaUrl('scf');
        $logAction("1. DIA URL alındı: $url");

        $session_id = Dia::getsessionid();
        $logAction("2. Session ID alındı: $session_id");

        $firma_kodu = 1;
        $donem_kodu = 1;
        
        if ($tur == 1) {
            $satirlar = $fis->getSatinAlmaSiparisFisSatirs()->with('urun')->all();
            $logAction("3. Satınalma sipariş satırları çekildi. Satır sayısı: " . count($satirlar));
        } else {
            $satirlar = $fis->getSatissatirlari()->all();
            $logAction("3. Satış sipariş satırları çekildi. Satır sayısı: " . count($satirlar));
        }

        $sira = 1;
        $kalemler = [];

        $satispersoneli = Satiscilar::find()->where(["kodu" => $fis->satispersoneli])->one();
        $logAction("4. Satış personeli bulundu: " . ($satispersoneli ? $satispersoneli->kodu . ' (' . $satispersoneli->_key . ')' : 'BULUNAMADI'));

        $depoKodu = (string) "44.03.01";
        $logAction("5. Depo kodu ayarlandı: $depoKodu");

        $logAction("6. Kalemler oluşturuluyor...");
        foreach ($satirlar as $satir) {
            $logAction("   - Satır #$sira işleniyor...");
            $sd = [];
            $stok = null;
            $birimAlani = null;

            if ($satir instanceof \app\models\SatinAlmaSiparisFisSatir) {
                if (!$satir->urun) {
                    $logAction("     UYARI: Satınalma satırı için ürün bulunamadı, atlanıyor.");
                    continue;
                }
                $stok = $satir->urun;
                $birimAlani = $satir->birim;
            } else {
                $stok = Urunler::find()->where(["StokKodu" => $satir->StokKodu])->one();
                if (!$stok) {
                    $logAction("     UYARI: Satış satırı için ürün bulunamadı (StokKodu: {$satir->StokKodu}), atlanıyor.");
                    continue;
                }
                $birimAlani = $satir->BirimTipi;
            }
            $logAction("     Stok Kodu: {$stok->StokKodu}, Birim Alanı: $birimAlani");

            if (strtoupper($birimAlani) == "UNIT") {
                $birimkey = $stok->BirimKey1;
            } else {
                $birimkey = $stok->BirimKey2;
            }
            $logAction("     Birim Key: $birimkey");

            $satirtutari = 0;
            $satirkdv = 0;

            $sd = [
                "sirano" => $sira,
                "rezervasyon" => "H",
                "onay" => "KABUL",
                "_key_kalemturu" => ["stokkartkodu" => $stok->StokKodu],
                "_key_scf_kalem_birimleri" => $birimkey,
                "_key_sis_depo_source" => ["depokodu" => $depoKodu],
                "_key_sis_doviz" => ["adi" => "GBP"],
                "anamiktar" => $satir->Miktar,
                "birimfiyati" => $satir->BirimFiyat ?? 0,
                "dovizkuru" => "1.000000",
                "kalemturu" => "MLZM",
                "kdv" =>  $stok->Vat,
                "kdvdurumu" => "H",
                "kdvtutari" => $satirkdv,
                "miktar" =>  $satir->Miktar,
                "onay" => "KABUL",
                "siptarih" => $fis->Fistarihi,
                "sonbirimfiyati" => $satir->BirimFiyat ?? 0,
                "tutari" => $satirtutari,
                "yerelbirimfiyati" => $satir->BirimFiyat ?? 0,
                "indirim1" => $satir->Iskonto,
                "note"=>$satir->comment
            ];
            $kalemler[] = $sd;
            $logAction("     Kalem oluşturuldu ve eklendi.");
            $sira++;
        }

        $data = [
            "scf_siparis_ekle" => [
                "session_id" => $session_id,
                "firma_kodu" => 1,
                "donem_kodu" => 1,
                "kart" => [
                    "_key_scf_carikart" => ["carikartkodu" => $fis->MusteriId],
                    "_key_sis_depo_source" => ["depokodu" => "44.03.01"],
                    "_key_sis_doviz" => ["adi" => "GBP"],
                    "_key_sis_doviz_raporlama" => ["adi" => "GBP"],
                    "_key_sis_ozelkod1" => 0,
                    "_key_sis_ozelkod2" => 0,
                    "_key_sis_sube_source" => ["subekodu" => "44.03"],
                    "aciklama1" => $fis->comment,
                    "teslimattarihi" => $fis->deliverydate,
                    "_key_scf_satiselemani" => $satispersoneli->_key,
                    "dovizkuru" => "1.000000",
                    "ekalan1" => "",
                    "fisno" => $fis->FisNo,
                    "m_kalemler" => $kalemler,
                    "net" => "0.000000",
                    "netdvz" => "0.000000",
                    "odemeislemli" => "f",
                    "odemeli" => "f",
                    "onay" => "KABUL",
                    "ortalamavade" => $fis->Fistarihi,
                    "raporlamadovizkuru" => "1.000000",
                    "saat" => date("H:i:s"),
                    "tarih" => date("Y-m-d"),
                    "teslimat_adres1" => "",
                    "teslimat_adres2" => "",
                    "teslimat_adsoyad" => "",
                    "teslimat_ceptel" => "",
                    "teslimat_ilce" => "",
                    "teslimat_key_sis_sehirler" => 0,
                    "teslimat_telefon" => "",
                    "toplam" => "00.000000",
                    "toplamdvz" => "0.000000",
                    "toplamindirim" => "0.000000",
                    "toplamindirimdvz" => "0.000000",
                    "toplamkdv" => "0.000000",
                    "toplamkdvdvz" => "0.000000",
                    "toplammasraf" => "0.000000",
                    "toplammasrafdvz" => "0.000000",
                    "turu" => 2
                ]
            ]
        ];
        
        $jsonData = json_encode($data, JSON_UNESCAPED_UNICODE);
        $logAction("7. DIA'ya gönderilecek JSON hazırlandı:\n" . json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));

        $logAction("8. cURL isteği başlatılıyor...");
        $curl = curl_init();
        curl_setopt($curl, CURLOPT_URL,  $url);
        curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($curl, CURLOPT_POSTFIELDS, $jsonData);
        curl_setopt($curl, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'Content-Length: ' . strlen($jsonData)
        ]);
        curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);
        
        $result = curl_exec($curl);
        $logAction("9. cURL isteği tamamlandı. Ham Sonuç:\n" . $result);
        
        if (curl_errno($curl)) {
            $hataMesaji = 'cURL hatası: ' . curl_error($curl) . ' - ' . date('Y-m-d H:i:s') . PHP_EOL;
            file_put_contents('runtime/curl_hatalari.txt', $hataMesaji, FILE_APPEND | LOCK_EX);
            $logAction("HATA: cURL hatası oluştu: " . curl_error($curl));
            $sonuc = 0;
        } else {
            $sonuc = 1;
            $json = json_decode($result, true);
            $logAction("10. Yanıt JSON olarak çözüldü:\n" . print_r($json, true));

            if (isset($json["code"]) && $json["code"] == "200") {
                $logAction("11. Başarılı yanıt (code 200) alındı. DIA Key: " . ($json["key"] ?? 'YOK'));
                $fis->diakey = $json["key"];
                if (!$fis->save()) {
                    $logAction("HATA: Fişe 'diakey' kaydedilemedi. Hatalar: " . json_encode($fis->getErrors()));
                } else {
                    $logAction("Fişe 'diakey' başarıyla kaydedildi.");
                }
            } else {
                $logAction("HATA: DIA'dan başarısız yanıt alındı. Code: " . ($json["code"] ?? 'N/A') . ", Mesaj: " . ($json["msg"] ?? 'N/A'));
            }
        }
        
        curl_close($curl);
        $logAction("12. cURL bağlantısı kapatıldı.");
        $logAction("--- siparisgondermobil LOG SON ---");
        return $sonuc;
    }
    public static function Si($fis,$tur=1){
        $logFile = Yii::getAlias('@runtime') . '/siparisgonder_log_' . date('Ymd_His') . '.txt';
        $logContent = '';
        $url = self::getDiaUrl('scf');
        $session_id = Dia::getsessionid();
        $firma_kodu = 1;
        $donem_kodu = 1;
        if($tur==1)          
            $satirlar=$fis->getSatinAlmaSiparisFisSatirs()->with('urun')->all();
        else 
            $satirlar=$fis->getSatissatirlari()->all();
        $sira=1;
        $kalemler = [];
        foreach ($satirlar as $satir) {
            $sd=[];
            $stok = null;
            $birimAlani = null;
            if($tur==1)
                $stno=$satir->urun_id;
            else 
                $stno=$stok->StokKodu;

            if ($satir instanceof \app\models\SatinAlmaSiparisFisSatir) { // Satınalma sipariş satırı ise
                if (!$satir->urun) continue; // İlişkili ürün yoksa atla
                $stok = $satir->urun;
                $birimAlani = $satir->birim; // birim alanı kullanılıyor
            } else { // Satış sipariş satırı ise (varsayılan)
                $stok = Urunler::find()->where(["StokKodu" =>$stno ])->one();
                if (!$stok) continue;
                $birimAlani = $satir->BirimTipi; // BirimTipi alanı olduğu varsayılıyor
            }

            if($birimAlani=="UNIT")
                $birimkey=$stok->BirimKey1;
            else
                $birimkey=$stok->BirimKey2;

            $satirtutari=0;//$satir->BirimFiyat*$satir->Miktar*(1-$satir->Iskonto/100);
            $satirkdv=0;//$satirtutari*$satir->vat/100;
            $sd=[
                "_key_kalemturu" => ["stokkartkodu" => $stno],
                "_key_scf_kalem_birimleri" => $birimkey,
                "_key_sis_depo_source" => ["depokodu" => "44.03.01"],
                "_key_sis_doviz" => ["adi" => "GBP"],
                "anamiktar" =>$satir->miktar,
                "birimfiyati" =>$satir->BirimFiyat??0,
                "dovizkuru" => "1.000000",
                "kalemturu" => "MLZM",
                "kdv" =>  $stok->Vat,
                "kdvdurumu" => "H",
                "kdvtutari" =>$satirkdv,
                "miktar" =>  $satir->miktar,
                "onay" => "KABUL",
                "rezervasyon" => "H",
                "siptarih" => $fis->satinalmasiparisfis->tarih,
                "sirano" => $sira,
                "sonbirimfiyati" => $satir->BirimFiyat??0,
                "tutari" => $satirtutari,
                "yerelbirimfiyati" => $satir->BirimFiyat??0,
                "m_varyantlar" => []
            ];
            $kalemler[]=$sd;
            $sira++;
        }
        $data = [
            "scf_siparis_ekle" => [
                "session_id" => $session_id,
                "firma_kodu" => 1,
                "donem_kodu" => 1,
                "kart" => [
                    "_key_scf_carikart" => ["carikartkodu" =>$fis->tedarikci->tedarikci_kodu],
                    "_key_sis_depo_source" => ["depokodu" => "44.03.01"],
                    "_key_sis_doviz" => ["adi" => "GBP"],
                    "_key_sis_doviz_raporlama" => ["adi" => "GBP"],
                    "_key_sis_ozelkod1" => 0,
                    "_key_sis_ozelkod2" => 0,
                    "_key_sis_sube_source" => ["subekodu" => "44.03"],
                    "aciklama1" => "",
                    "dovizkuru" => "1.000000",
                    "ekalan1" => "",
                    "fisno" => $fis->fisno,
                    "m_kalemler" => $kalemler,
                    "net" => "0.000000",
                    "netdvz" => "0.000000",
                    "odemeislemli" => "f",
                    "odemeli" => "f",
                    "onay" => "KABUL",
                    "ortalamavade" => $fis->satinalmasiparisfis->tarih,
                    "raporlamadovizkuru" => "1.000000",
                    "saat" => date("H:i:s"),
                    "tarih" => date("Y-m-d"),
                    "teslimat_adres1" => "",
                    "teslimat_adres2" => "",
                    "teslimat_adsoyad" => "",
                    "teslimat_ceptel" => "",
                    "teslimat_ilce" => "",
                    "teslimat_key_sis_sehirler" => 0,
                    "teslimat_telefon" => "",
                    "toplam" => "00.000000",
                    "toplamdvz" => "0.000000",
                    "toplamindirim" => "0.000000",
                    "toplamindirimdvz" => "0.000000",
                    "toplamkdv" => "0.000000",
                    "toplamkdvdvz" => "0.000000",
                    "toplammasraf" => "0.000000",
                    "toplammasrafdvz" => "0.000000",
                    "turu" => 1
                ]
            ]
        ];
        
        $jsonData = json_encode($data);
       // echo $jsonData;
        // cURL başlat
        $curl = curl_init();
        curl_setopt($curl, CURLOPT_URL,  $url); // Burada $newUrl kullanıyoruz
        curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($curl, CURLOPT_POSTFIELDS, $jsonData);
        curl_setopt($curl, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'Content-Length: ' . strlen($jsonData)
        ]);
        
        curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false); // Sertifika doğrulamasını kapatıyoruz (test amaçlı)
        
        $result = curl_exec($curl);
        print_r($result);
        // Eğer cURL hatası varsa yazdır
        $logContent .= "[".date('Y-m-d H:i:s')."] API Response: " . $result . "\n";
        if (curl_errno($curl)) {
            $hataMesaji = 'cURL hatası: ' . curl_error($curl) . ' - ' . date('Y-m-d H:i:s') . PHP_EOL;
            file_put_contents('runtime/curl_hatalari.txt', $hataMesaji, FILE_APPEND | LOCK_EX);
           $sonuc=0;
            $errorMsg = 'cURL hatası: ' . curl_error($curl);
            $logContent .= "[".date('Y-m-d H:i:s')."] ERROR: $errorMsg\n";
            file_put_contents($logFile, $logContent);
            curl_close($curl);
            return 0;
        } else {
            $json = json_decode($result, true);
            $logContent .= "[".date('Y-m-d H:i:s')."] JSON Decode: " . print_r($json, true) . "\n";
            $logContent .= "[".date('Y-m-d H:i:s')."] Fis Errors: " . print_r($fis->errors, true) . "\n";
            file_put_contents($logFile, $logContent);
            curl_close($curl);
            return 1;
        }
    }
    public static function siparislistele($startDate,$endDate){
        if($startDate == null){
            $startDate = date('Y-m-d 00:00:00', strtotime('-1 day'));
        }
        if($endDate == null){
            $endDate = date('Y-m-d 23:59:59');
        }
        $url = self::getDiaUrl('scf');
        $session_id = Dia::getsessionid();
        $firma_kodu = 1;
        $donem_kodu = 1;

        $data = [
            "scf_siparis_listele" => [
                "session_id" => $session_id,
                "firma_kodu" => $firma_kodu,
                "donem_kodu" => $donem_kodu,
                "filters" => [
                    ["field" => "_cdate", "operator" => ">=", "value" => $startDate],
                    ["field" => "_cdate", "operator" => "<=", "value" => $endDate],
                    ["field" => "turu", "operator" => "IN", "value" => "1,2,3"],
                ],
            ]
        ];

        $jsonData = json_encode($data);
        $curl = curl_init();
        curl_setopt($curl, CURLOPT_URL, $url);
        curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($curl, CURLOPT_POSTFIELDS, $jsonData);
        curl_setopt($curl, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'Content-Length: ' . strlen($jsonData)
        ]);
        curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);
        // Timeout ayarları ekle
        curl_setopt($curl, CURLOPT_TIMEOUT, 120); // 2 dakika
        curl_setopt($curl, CURLOPT_CONNECTTIMEOUT, 30); // 30 saniye bağlantı timeout

        $result = curl_exec($curl);
        if (curl_errno($curl)) {
            Yii::error('Sipariş listele cURL hatası: ' . curl_error($curl), 'dia');
            curl_close($curl);
            return null;
        } else {
            $json = json_decode($result, true);
            curl_close($curl);
            return $json['result'] ?? null;
        }
    }
    public static function siparislisteleayrintili($startDate,$endDate){
        if($startDate == null){
            $startDate = date('Y-m-d 00:00:00', strtotime('-1 day'));
        }
        if($endDate == null){
            $endDate = date('Y-m-d 23:59:59');
        }
        $url = self::getDiaUrl('scf');
        $session_id = Dia::getsessionid();
        $firma_kodu = 1;
        $donem_kodu = 1;
 
        $data = [
            "scf_siparis_listele_ayrintili" => [
                "session_id" => $session_id,
                "firma_kodu" => $firma_kodu,
                "donem_kodu" => $donem_kodu,
                "filters" => [
                    ["field" => "_cdate", "operator" => ">=", "value" => $startDate],
                    ["field" => "_cdate", "operator" => "<=", "value" => $endDate],
                    ["field" => "turu", "operator" => "IN", "value" => "1,2,3"],
                ],
            ]
        ];

        // Log the request data
        $requestLogPath = Yii::getAlias('@app/runtime/siparis_ayrintili_request_'.date("Ymdhis").'.txt');
        $requestLog = "URL: " . $url . "\n";
        $requestLog .= "Session ID: " . $session_id . "\n";
        $requestLog .= "Start Date: " . $startDate . "\n";
        $requestLog .= "End Date: " . $endDate . "\n";
        $requestLog .= "Request Data: \n" . json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
       // file_put_contents($requestLogPath, $requestLog);

        $jsonData = json_encode($data);
        $curl = curl_init();
        curl_setopt($curl, CURLOPT_URL, $url);
        curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($curl, CURLOPT_POSTFIELDS, $jsonData);
        curl_setopt($curl, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'Content-Length: ' . strlen($jsonData)
        ]);
        curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);
        // Timeout ayarları ekle
        curl_setopt($curl, CURLOPT_TIMEOUT, 60); // 1 dakika
        curl_setopt($curl, CURLOPT_CONNECTTIMEOUT, 15); // 15 saniye bağlantı timeout

        $result = curl_exec($curl);
        
        if (curl_errno($curl)) {
            $error = curl_error($curl);
            Yii::error('Sipariş ayrıntı cURL hatası: ' . $error, 'dia');
            curl_close($curl);
            return null;
        } else {
            $json = json_decode($result, true);
            curl_close($curl);
            return $json['result'] ?? null;
        }
    }
    public static function siparislisteleayrintilibykey($startDate,$endDate, $siparis_key){
        if($startDate == null){
            $startDate = date('Y-m-d 00:00:00', strtotime('-1 day'));
        }
        if($endDate == null){
            $endDate = date('Y-m-d 23:59:59');
        }
        $url = self::getDiaUrl('scf');
        $session_id = Dia::getsessionid();
        $firma_kodu = 1;
        $donem_kodu = 1;
 
        $data = [
            "scf_siparis_listele_ayrintili" => [
                "session_id" => $session_id,
                "firma_kodu" => $firma_kodu,
                "donem_kodu" => $donem_kodu,
                "filters" => [
                    ["field" => "_cdate", "operator" => ">=", "value" => $startDate],
                    ["field" => "_cdate", "operator" => "<=", "value" => $endDate],
                    ["field" => "_key_scf_siparis", "operator" => "=", "value" => $siparis_key]
                ],
                "sorts" => "",
                "params" => "",
                "offset" => 0
            ]
        ];

        // Log the request data
        $requestLogPath = Yii::getAlias('@app/runtime/siparis_ayrintili_request_'.date("Ymdhis").'.txt');
        $requestLog = "URL: " . $url . "\n";
        $requestLog .= "Session ID: " . $session_id . "\n";
        $requestLog .= "Start Date: " . $startDate . "\n";
        $requestLog .= "End Date: " . $endDate . "\n";
        $requestLog .= "Request Data: \n" . json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
       // file_put_contents($requestLogPath, $requestLog);

        $jsonData = json_encode($data);
        $curl = curl_init();
        curl_setopt($curl, CURLOPT_URL, $url);
        curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($curl, CURLOPT_POSTFIELDS, $jsonData);
        curl_setopt($curl, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'Content-Length: ' . strlen($jsonData)
        ]);
        curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);
        // Timeout ayarları ekle
        curl_setopt($curl, CURLOPT_TIMEOUT, 60); // 1 dakika
        curl_setopt($curl, CURLOPT_CONNECTTIMEOUT, 15); // 15 saniye bağlantı timeout

        $result = curl_exec($curl);
        
        if (curl_errno($curl)) {
            $error = curl_error($curl);
            Yii::error('Sipariş ayrıntı cURL hatası: ' . $error, 'dia');
            curl_close($curl);
            return null;
        } else {
            $json = json_decode($result, true);
            curl_close($curl);
            return $json['result'] ?? null;
        }
    }
    public static function urunBilgiGetir($stokkartkodu){
        $url = self::getDiaUrl('scf');

        $session_id = Dia::getsessionid();
        $firma_kodu = 1;
        $donem_kodu = 1;

        $data = [
            "scf_urun_ozellik_getir" => [
                "session_id" => $session_id,
                "firma_kodu" => $firma_kodu,
                "donem_kodu" => $donem_kodu,
                "filters" =>[
                    ["field" => "durum", "operator" => "=", "value" => "A"],
                    ["field" => "stokkartkodu","operator" => "=", "value" => $stokkartkodu],
                ],
                "sorts" =>  [
                    ["field" => "stokkartkodu", "sorttype" => "DESC"]],
                "params" => [
                    "_key_sis_depo" => 0,
                    "_key_sis_depo_filtre" => 0,
                    "tarih" => "2099-12-31",

                ],
                "limit" => 5,
                "offset" => 0
            ]
        ];

        $jsonData = json_encode($data);
        $curl = curl_init();
        curl_setopt($curl, CURLOPT_URL, $url);
        curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($curl, CURLOPT_POSTFIELDS, $jsonData);
        curl_setopt($curl, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'Content-Length: ' . strlen($jsonData)
        ]);
        curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);

        $result = curl_exec($curl);
        if (curl_errno($curl)) {
            $hataMesaji = 'cURL hatası: ' . curl_error($curl) . ' - ' . date('Y-m-d H:i:s') . PHP_EOL;
            file_put_contents('runtime/curl_hatalari.txt', $hataMesaji, FILE_APPEND | LOCK_EX);
            return null;
        } else {
            $json = json_decode($result, true);
            return $json;
        }
        curl_close($curl);
    }
    public static function cariKartGetir($cari_key){
        $url = self::getDiaUrl('scf');

        $session_id = Dia::getsessionid();
        $firma_kodu = 1;
        $donem_kodu = 1;

        $data = [
            "scf_carikart_getir" => [
                "session_id" => $session_id,
                "firma_kodu" => $firma_kodu,
                "donem_kodu" => $donem_kodu,
                "key" => $cari_key
            ]
        ];

        $jsonData = json_encode($data);
        $curl = curl_init();
        curl_setopt($curl, CURLOPT_URL, $url);
        curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($curl, CURLOPT_POSTFIELDS, $jsonData);
        curl_setopt($curl, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'Content-Length: ' . strlen($jsonData)
        ]);
        curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);

        $result = curl_exec($curl);
        if (curl_errno($curl)) {
            $hataMesaji = 'cURL hatası: ' . curl_error($curl) . ' - ' . date('Y-m-d H:i:s') . PHP_EOL;
            file_put_contents('runtime/curl_hatalari.txt', $hataMesaji, FILE_APPEND | LOCK_EX);
            return null;
        } else {
            $json = json_decode($result, true);
            return $json;
        }
        curl_close($curl);
    }
    public static function cariKartListele($cariKartKodlari = null){
        $url = self::getDiaUrl('scf');

        $session_id = Dia::getsessionid();
        $firma_kodu = 1;
        $donem_kodu = 1;

        $data = [
            "scf_carikart_listele" => [
                "session_id" => $session_id,
                "firma_kodu" => $firma_kodu,
                "donem_kodu" => $donem_kodu,
                "filters" => [
                    ["field" => "carikartkodu", "operator" => "IN", "value" => "$cariKartKodlari"]
                ],
            ]
        ];

        $jsonData = json_encode($data);
        // Log REQUEST
        try {
            $logPrefix = '[' . date('Y-m-d H:i:s') . '] ';
            $reqLog = $logPrefix . 'REQUEST scf_carikart_listele carikodu=' . (string)$cariKartKodlari . ' payload=' . $jsonData . "\n";
            file_put_contents(\Yii::getAlias('@app/runtime/dia_cari_listele_log.txt'), $reqLog, FILE_APPEND);
        } catch (\Throwable $e) { /* ignore logging errors */ }
        $curl = curl_init();
        curl_setopt($curl, CURLOPT_URL, $url);
        curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($curl, CURLOPT_POSTFIELDS, $jsonData);
        curl_setopt($curl, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'Content-Length: ' . strlen($jsonData)
        ]);
        curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);

        $result = curl_exec($curl);
        if (curl_errno($curl)) {
            $hataMesaji = 'cURL hatası: ' . curl_error($curl) . ' - ' . date('Y-m-d H:i:s') . PHP_EOL;
            try { file_put_contents(\Yii::getAlias('@app/runtime/curl_hatalari.txt'), $hataMesaji, FILE_APPEND | LOCK_EX); } catch (\Throwable $e) {}
            // Log RESPONSE (error)
            try {
                $logPrefix = '[' . date('Y-m-d H:i:s') . '] ';
                $resLog = $logPrefix . 'RESPONSE scf_carikart_listele carikodu=' . (string)$cariKartKodlari . ' cURL_ERROR=' . curl_error($curl) . "\n";
                file_put_contents(\Yii::getAlias('@app/runtime/dia_cari_listele_log.txt'), $resLog, FILE_APPEND);
            } catch (\Throwable $e) { }
            return null;
        } else {
            $json = json_decode($result, true);
            // Log RESPONSE (success)
            try {
                $logPrefix = '[' . date('Y-m-d H:i:s') . '] ';
                $resLog = $logPrefix . 'RESPONSE scf_carikart_listele carikodu=' . (string)$cariKartKodlari . ' body=' . $result . "\n";
                file_put_contents(\Yii::getAlias('@app/runtime/dia_cari_listele_log.txt'), $resLog, FILE_APPEND);
            } catch (\Throwable $e) { }
            return $json;
        }
        curl_close($curl);
    }
    public static function irsaliyeEkle($data = null)
    {
        $startTime = microtime(true);
        
        try {
            $url = self::getDiaUrl('scf');

            // If no data is provided, use default values
            if ($data === null) {
                $session_id = Dia::getsessionid();
                $firma_kodu = 1;
                $donem_kodu = 1;

                $data = [
                    "scf_irsaliye_ekle" => [
                        "session_id" => $session_id,
                        "firma_kodu" => $firma_kodu,
                        "donem_kodu" => $donem_kodu,
                        "kart" => [
                            "_key_ith_kart_ihr" => 0,
                            "_key_ith_kart_ith" => 0,
                            "_key_karsi_irsaliye" => 0,
                            "_key_krg_firma" => 0,
                            "_key_krg_gonderifisi" => 0,
                            "_key_muh_masrafmerkezi" => 0,
                            "_key_prj_proje" => ["kodu" => "000006"],
                            "_key_satiselemanlari" => [],
                            "_key_scf_carikart" => ["carikartkodu" => "0000008"],
                            "_key_scf_carikart_adresleri" => 178718,
                            "_key_scf_fatura" => 0,
                            "_key_scf_odeme_plani" => ["kodu" => "000008"],
                            "_key_scf_satiselemani" => 0,
                            "_key_scf_sevkaraci" => 0,
                            "_key_sis_depo_dest" => 0,
                            "_key_sis_depo_source" => ["depokodu" => "DEPO001"],
                            "_key_sis_devir" => 0,
                            "_key_sis_doviz" => ["adi" => "TL"],
                            "_key_sis_doviz_raporlama" => ["adi" => "TL"],
                            "_key_sis_firma_dest" => 0,
                            "_key_sis_ozelkod1" => 0,
                            "_key_sis_ozelkod2" => 0,
                            "_key_sis_seviyekodu" => 0,
                            "_key_sis_sube_dest" => 0,
                            "_key_sis_sube_source" => ["subekodu" => "SUBE001"],
                            "aciklama1" => "",
                            "aciklama2" => "",
                            "aciklama3" => "",
                            "bagkur" => "0.000000",
                            "bagkurdvz" => "0.000000",
                            "bagkuryuzde" => "0.000000",
                            "belgeno" => "000009",
                            "belgeno2" => "WS000001",
                            "borsa" => "0.000000",
                            "borsadvz" => "0.000000",
                            "borsayuzde" => "0.000000",
                            "dovizkuru" => "1.000000",
                            "ekalan1" => "",
                            "ekmaliyet" => "0.000000",
                            "fisno" => "WS00001",
                            "iptal" => "-",
                            "iptalnedeni" => "",
                            "istemcitipi" => "G",
                            "ithtipi" => "0",
                            "kargogonderimtarihi" => null,
                            "karsifirma" => "C",
                            "kdvduzenorani" => "+",
                            "kdvduzentutari" => "0.000000",
                            "kdvtebligi85" => "f",
                            "kilitli" => "f",
                            "kurguncelleme" => "",
                            "m_kalemler" => [[
                                "_key_kalemturu" => 177417,
                                "_key_muh_masrafmerkezi" => 0,
                                "_key_prj_proje" => ["kodu" => "000006"],
                                "_key_scf_fiyatkart" => 0,
                                "_key_scf_irsaliye_kalemi_iade" => 0,
                                "_key_scf_irsaliye_kalemi_oncekidonem" => 0,
                                "_key_scf_kalem_birimleri" => 177418,
                                "_key_scf_karsi_irsaliye_kalemi" => 0,
                                "_key_scf_odeme_plani" => 0,
                                "_key_scf_promosyon" => 0,
                                "_key_scf_satiselemani" => 0,
                                "_key_scf_siparis_kalemi" => 0,
                                "_key_sis_depo_dest" => 0,
                                "_key_sis_depo_source" => ["depokodu" => "DEPO001"],
                                "_key_sis_doviz" => ["adi" => "TL"],
                                "_key_sis_ozelkod" => 0,
                                "anamiktar" => "6.000000",
                                "birimfiyati" => "658.000000",
                                "dovizkuru" => "1.000000",
                                "irstarih" => "2024-05-10",
                                "kalemturu" => "MLZM",
                                "kdv" => "18.000000",
                                "kdvdurumu" => "H",
                                "kdvtevkifatorani" => "0",
                                "kdvtevkifattutari" => "0.000000",
                                "kdvtutari" => "710.640000",
                                "miktar" => "6.000000",
                                "note" => "",
                                "note2" => "",
                                "ovkdvoran" => "E",
                                "ovkdvtutar" => "E",
                                "ovmanuel" => "H",
                                "ozelalanf" => "",
                                "promosyonkalemid" => "",
                                "sirano" => 10,
                                "sonbirimfiyati" => "658.000000",
                                "tutari" => "3948.000000",
                                "yerelbirimfiyati" => "658.000000",
                                "m_varyantlar" => []
                            ]],
                            "navlun" => "0.000000",
                            "navlundvz" => "0.000000",
                            "navlunkdv" => "0.000000",
                            "navlunkdvdvz" => "0.000000",
                            "navlunkdvyuzde" => "0.000000",
                            "net" => "4658.640000",
                            "netdvz" => "4658.640000",
                            "ortalamavade" => "2024-09-07",
                            "raporlamadovizkuru" => "1.000000",
                            "saat" => "15:01:51",
                            "sevkadresi1" => "YILDIRIMÖNÜ MAH. ÇAMDALI SOK. NO:118",
                            "sevkadresi2" => "",
                            "sevkadresi3" => "Keçiören ANKARA",
                            "ssdf" => "0.000000",
                            "tarih" => "2024-05-10",
                            "toplam" => "3948.000000",
                            "toplamdvz" => "3948.000000",
                            "toplamkdv" => "710.640000",
                            "toplamkdvdvz" => "710.640000",
                            "toplamov" => "0.000000",
                            "toplamovdvz" => "0.000000",
                            "turu" => 1
                        ]
                    ]
                ];
            }
            
            // Encode the data - whether it's the default or provided data
            $jsonData = json_encode($data);
            // Belge/Fis numarasını log dosya adlarında kullanmak için hazırla
            $belgeNo = null;
            if (isset($data['scf_irsaliye_ekle']) && isset($data['scf_irsaliye_ekle']['kart'])) {
                $belgeNo = $data['scf_irsaliye_ekle']['kart']['belgeno'] ?? ($data['scf_irsaliye_ekle']['kart']['fisno'] ?? null);
            }
            $safeBelge = $belgeNo ? preg_replace('/[^A-Za-z0-9_-]/', '_', (string)$belgeNo) : 'NA';
            
            if ($jsonData === false) {
                $errorLogFile = Yii::getAlias('@app/runtime/dia_irsaliye_errors_' . date('Y_m_d') . '.txt');
                $errorMessage = date('Y-m-d H:i:s') . " - JSON ENCODE HATASI: " . json_last_error_msg() . "\n";
                file_put_contents($errorLogFile, $errorMessage, FILE_APPEND | LOCK_EX);
                return null;
            }

            $curl = curl_init();
            
            curl_setopt($curl, CURLOPT_URL, $url);
            curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
            curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($curl, CURLOPT_POSTFIELDS, $jsonData);
            curl_setopt($curl, CURLOPT_HTTPHEADER, [
                'Content-Type: application/json',
                'Content-Length: ' . strlen($jsonData)
            ]);
            curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);
            curl_setopt($curl, CURLOPT_TIMEOUT, 30);
            curl_setopt($curl, CURLOPT_CONNECTTIMEOUT, 10);
            
            $result = curl_exec($curl);
            $requestTime = microtime(true) - $startTime;
            
            // Detaylı curl bilgileri al
            $curlInfo = curl_getinfo($curl);
            $curlError = curl_error($curl);
            $curlErrno = curl_errno($curl);
            
            if (curl_errno($curl)) {
                $error = curl_error($curl);
                $httpCode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
                
                curl_close($curl);
                
                // Sadece hata durumlarında log dosyasına yaz
                $errorLogFile = Yii::getAlias('@app/runtime/dia_irsaliye_errors_' . date('Y_m_d') . '.txt');
                $errorMessage = date('Y-m-d H:i:s') . " - CURL HATASI: $error - HTTP: $httpCode\n";
                file_put_contents($errorLogFile, $errorMessage, FILE_APPEND | LOCK_EX);
                
                $hataMesaji = 'cURL hatası: ' . $error . ' - ' . date('Y-m-d H:i:s') . ' - HTTP: ' . $httpCode . PHP_EOL;
                file_put_contents(Yii::getAlias('@app/runtime/curl_hatalari.txt'), $hataMesaji, FILE_APPEND | LOCK_EX);
                
                // Ayrıntılı TXT log: istek/yanıt/curl info
                $detailPath = Yii::getAlias('@app/runtime/irsaliye_curl_error_' . date('YmdHis') . '_' . $safeBelge . '.txt');
                $detail = [
                    'ts' => date('c'),
                    'type' => 'curl_error',
                    'http' => $httpCode,
                    'curl_error' => $error,
                    'curl_errno' => $curlErrno,
                    'curl_info' => $curlInfo,
                    'request_time_ms' => (int)round($requestTime * 1000),
                    'url' => $url,
                    'request' => $data,
                ];
                @file_put_contents($detailPath, json_encode($detail, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
                
                return null;
            } else {
                $httpCode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
                
                curl_close($curl);
                
                $json = json_decode($result, true);
                
                if ($json === null && json_last_error() !== JSON_ERROR_NONE) {
                    $errorLogFile = Yii::getAlias('@app/runtime/dia_irsaliye_errors_' . date('Y_m_d') . '.txt');
                    $errorMessage = date('Y-m-d H:i:s') . " - JSON DECODE HATASI: " . json_last_error_msg() . " - Response: " . substr($result, 0, 500) . "\n";
                    file_put_contents($errorLogFile, $errorMessage, FILE_APPEND | LOCK_EX);
                    // Ayrıntılı TXT log
                    $detailPath = Yii::getAlias('@app/runtime/irsaliye_json_error_' . date('YmdHis') . '_' . $safeBelge . '.txt');
                    $detail = [
                        'ts' => date('c'),
                        'type' => 'json_decode_error',
                        'http' => $httpCode,
                        'curl_info' => $curlInfo,
                        'request_time_ms' => (int)round($requestTime * 1000),
                        'url' => $url,
                        'request' => $data,
                        'response_snippet' => substr((string)$result, 0, 2000),
                        'json_error' => json_last_error_msg(),
                    ];
                    @file_put_contents($detailPath, json_encode($detail, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
                    
                    return null;
                }
                
                // Sadece hata durumlarında log dosyasına yaz
                $isSuccess = false;
                if (is_array($json)) {
                    // code 200 veya success true ise başarılı
                    if ((isset($json['code']) && ($json['code'] == '200' || $json['code'] == 200)) || 
                        (isset($json['success']) && $json['success'])) {
                        $isSuccess = true;
                    }
                }
                
                if (!$isSuccess) {
                    $resultLogFile = Yii::getAlias('@app/runtime/irsaliye_basarisiz_' . date('Y_m_d') . '.txt');
                    $resultLogMessage = date('Y-m-d H:i:s') . " - ";
                    if (isset($data['scf_irsaliye_ekle']['kart']['belgeno'])) {
                        $resultLogMessage .= "Belge: " . $data['scf_irsaliye_ekle']['kart']['belgeno'] . " - ";
                    }
                    $resultLogMessage .= "Result: " . json_encode($json) . "\n";
                    file_put_contents($resultLogFile, $resultLogMessage, FILE_APPEND | LOCK_EX);
                    // Ayrıntılı TXT log (istek + yanıt)
                    $detailPath = Yii::getAlias('@app/runtime/irsaliye_fail_' . date('YmdHis') . '_' . $safeBelge . '.txt');
                    $detail = [
                        'ts' => date('c'),
                        'type' => 'business_fail',
                        'http' => $httpCode,
                        'curl_info' => $curlInfo,
                        'request_time_ms' => (int)round($requestTime * 1000),
                        'url' => $url,
                        'request' => $data,
                        'response' => $json,
                    ];
                    @file_put_contents($detailPath, json_encode($detail, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
                }
                
                return $json;
            }
            
        } catch (\Exception $e) {
            $errorLogFile = Yii::getAlias('@app/runtime/dia_irsaliye_errors_' . date('Y_m_d') . '.txt');
            $errorMessage = date('Y-m-d H:i:s') . " - DIA COMPONENT EXCEPTION: " . $e->getMessage() . " - File: " . $e->getFile() . " - Line: " . $e->getLine() . "\n";
            file_put_contents($errorLogFile, $errorMessage, FILE_APPEND | LOCK_EX);
            
            return null;
        }
    }
    public static function subeDepolarGetir(){
        $url = self::getDiaUrl('sis');

        $session_id = Dia::getsessionid();
        $firma_kodu = 1;
        $donem_kodu = 1;

        $data = [
            "sis_yetkili_firma_donem_sube_depo" => [
                "session_id" => $session_id,
            ]
        ];

        $jsonData = json_encode($data);
        $curl = curl_init();
        curl_setopt($curl, CURLOPT_URL, $url);
        curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($curl, CURLOPT_POSTFIELDS, $jsonData);
        curl_setopt($curl, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'Content-Length: ' . strlen($jsonData)
        ]);
        curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);

        $result = curl_exec($curl);
        $result = PythonDictConverter::toJson($result);
        // Hata kontrolü ekleyelim
        if (curl_errno($curl)) {
            $error = curl_error($curl);
            curl_close($curl);
            Yii::error("cURL error: $error", __METHOD__);
            return ['error' => $error];
        }
        curl_close($curl);
        
        // Ham sonucu loglayalım
        Yii::info("Raw API response: $result", __METHOD__);
        
        // PythonDictConverter'ı kaldırıp doğrudan JSON decode edelim
        try {
            return json_decode($result, true);
        } catch (\Exception $e) {
            Yii::error("JSON decode error: " . $e->getMessage(), __METHOD__);
            return null;
        }
    }
    //ürünün depolardaki miktarlarını getirir
    public static function depoMiktarlariListele($urun_key){
        $url = self::getDiaUrl('scf');

        $session_id = Dia::getsessionid();
        $firma_kodu = 1;
        $donem_kodu = 1;

        $data = [
            "scf_stok_depo_miktarlari_listele" => [
                "session_id" => $session_id,
                "firma_kodu" => $firma_kodu,
                "donem_kodu" => $donem_kodu,
                "params" => [
                    "_key" => $urun_key,
                ]
            ]
        ];

        $jsonData = json_encode($data);
        $curl = curl_init();
        curl_setopt($curl, CURLOPT_URL, $url);
        curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($curl, CURLOPT_POSTFIELDS, $jsonData);
        curl_setopt($curl, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'Content-Length: ' . strlen($jsonData)
        ]);
        curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);

        $result = curl_exec($curl);
        $result = PythonDictConverter::toJson($result);
        // Hata kontrolü ekleyelim
        if (curl_errno($curl)) {
            $error = curl_error($curl);
            curl_close($curl);
            Yii::error("cURL error: $error", __METHOD__);
            return ['error' => $error];
        }
        curl_close($curl);
        
        // Ham sonucu loglayalım
        Yii::info("Raw API response: $result", __METHOD__);
        
        // PythonDictConverter'ı kaldırıp doğrudan JSON decode edelim
        try {
            return json_decode($result, true);
        } catch (\Exception $e) {
            Yii::error("JSON decode error: " . $e->getMessage(), __METHOD__);
            return null;
        }
    }
     //ürünün depolardaki miktarlarını getirir
    public static function stokkartHareketListele($urun_key, $startDate = null, $endDate = null){
        $url = self::getDiaUrl('scf');

        $session_id = Dia::getsessionid();
        $firma_kodu = 1;
        $donem_kodu = 1;

        $data = [
            "scf_stokkart_hareket_listele" => [
                "session_id" => $session_id,
                "firma_kodu" => $firma_kodu,
                "donem_kodu" => $donem_kodu,
                "params" => [
                    "_key" => $urun_key,
                ]
            ]
        ];

        if ($startDate && $endDate) {
            $data['scf_stokkart_hareket_listele']['filters'] = [
                ["field" => "tarih", "operator" => ">=", "value" => $startDate],
                ["field" => "tarih", "operator" => "<=", "value" => $endDate],
            ];
        }

        $jsonData = json_encode($data);
        $curl = curl_init();
        curl_setopt($curl, CURLOPT_URL, $url);
        curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($curl, CURLOPT_POSTFIELDS, $jsonData);
        curl_setopt($curl, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'Content-Length: ' . strlen($jsonData)
        ]);
        curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);

        $result = curl_exec($curl);
        $result = PythonDictConverter::toJson($result);
    
        // Hata kontrolü ekleyelim
        if (curl_errno($curl)) {
            $error = curl_error($curl);
            curl_close($curl);
            Yii::error("cURL error: $error", __METHOD__);
            return ['error' => $error];
        }
        curl_close($curl);
        
        // Ham sonucu loglayalım
        Yii::info("Raw API response: $result", __METHOD__);
        
        // Add logging to a file in runtime directory
        $logFilePath = Yii::getAlias('@runtime') . '/stok_hareket_log.json';
        file_put_contents($logFilePath, $result);

        // PythonDictConverter'ı kaldırıp doğrudan JSON decode edelim
        try {
            return json_decode($result, true);
        } catch (\Exception $e) {
            Yii::error("JSON decode error: " . $e->getMessage(), __METHOD__);
            return null;
        }
    }
    public static function getSatiscilar(){
        $url = self::getDiaUrl('scf');
        $session_id = Dia::getsessionid();
        $firma_kodu = 1;
        $donem_kodu = 1;
        Yii::$app->response->format = \yii\web\Response::FORMAT_RAW;
        Yii::$app->response->headers->set('Content-Type', 'text/plain; charset=UTF-8');

        $data = [
            "scf_satiselemani_listele" => [
                "session_id" => $session_id,
                "firma_kodu" => $firma_kodu,
                "donem_kodu" => $donem_kodu
            ]
        ];

        $jsonData = json_encode($data);
        $curl = curl_init();
        curl_setopt($curl, CURLOPT_URL, $url);
        curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($curl, CURLOPT_POSTFIELDS, $jsonData);
        curl_setopt($curl, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'Content-Length: ' . strlen($jsonData)
        ]);
        curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);

        $result = curl_exec($curl);
        if (curl_errno($curl)) {
            $hataMesaji = 'cURL hatası: ' . curl_error($curl) . ' - ' . date('Y-m-d H:i:s') . PHP_EOL;
            file_put_contents('runtime/curl_hatalari.txt', $hataMesaji, FILE_APPEND | LOCK_EX);
            return null;
        } else {
            $json = json_decode($result, true);
            return $result;//$json;
        }
        curl_close($curl);      
    }
    public static function faturaListele($startDate = null,$endDate = null,$raw=false){
        if($startDate==null){
            $startDate = date('Y-m-d', strtotime('-1 day'));
        }
        if($endDate==null){
            $endDate = date('Y-m-d');
        }
        
        // Tarih formatını basitleştir - direkt string olarak kullan
        $startDateFormatted = $startDate;
        $endDateFormatted = $endDate;
        
        $url = self::getDiaUrl('scf');
        $session_id = Dia::getsessionid();
        $firma_kodu = 1;
        $donem_kodu = 1;

        $data = [
            "scf_fatura_listele" => [
                "session_id" => $session_id,
                "firma_kodu" => $firma_kodu,
                "donem_kodu" => $donem_kodu,
                "filters" => [
                    ["field" => "tarih", "operator" => ">=", "value" => $startDateFormatted],
                    ["field" => "tarih", "operator" => "<=", "value" => $endDateFormatted],
                    ["field" => "turu", "operator" => "IN", "value" => "1,2,3"]
                ],
                "sorts" => "",
                "params" => "",
                "offset" => 0,
                "limit" => 30000,
            ]
        ];

        // Sade JSON log için tek dosya
        $logFile = Yii::getAlias('@app/runtime/dia_api.log');

        $jsonData = json_encode($data);
        $curl = curl_init();
        curl_setopt($curl, CURLOPT_URL, $url);
        curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($curl, CURLOPT_POSTFIELDS, $jsonData);
        curl_setopt($curl, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'Content-Length: ' . strlen($jsonData)
        ]);
        curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);
        // Timeout ayarları ekle
        curl_setopt($curl, CURLOPT_TIMEOUT, 180); // 3 dakika
        curl_setopt($curl, CURLOPT_CONNECTTIMEOUT, 45); // 45 saniye bağlantı timeout
        // TCP keepalive (varsa)
        if (defined('CURLOPT_TCP_KEEPALIVE')) {
            curl_setopt($curl, CURLOPT_TCP_KEEPALIVE, 1);
            curl_setopt($curl, CURLOPT_TCP_KEEPIDLE, 20);
            curl_setopt($curl, CURLOPT_TCP_KEEPINTVL, 15);
        }
        // Debug amaçlı verbose log
        $verboseFile = fopen(Yii::getAlias('@app/runtime/dia_curl_verbose.log'), 'a');
        curl_setopt($curl, CURLOPT_VERBOSE, true);
        curl_setopt($curl, CURLOPT_STDERR, $verboseFile);

        $execStart = microtime(true);
        $result = curl_exec($curl);
        $execEnd = microtime(true);
        $duration = round($execEnd - $execStart, 3);
        $info = curl_getinfo($curl);
        $httpCode = isset($info['http_code']) ? $info['http_code'] : 0;
        $transportInfoPath = Yii::getAlias('@app/runtime/dia_curl_info_fatura.txt');
        @file_put_contents($transportInfoPath, json_encode([
            'ts' => date('c'),
            'op' => 'faturaListele',
            'http' => $httpCode,
            'info' => $info,
            'request' => $data,
            'duration' => $duration
        ], JSON_UNESCAPED_UNICODE) . PHP_EOL, FILE_APPEND | LOCK_EX);

        if (curl_errno($curl)) {
            $errorMsg = curl_error($curl);
            $logRow = [
                'ts' => date('c'),
                'op' => 'faturaListele',
                'start' => $startDate,
                'end' => $endDate,
                'http' => $httpCode,
                'dur_ms' => (int)round($duration * 1000),
                'status' => 'error',
                'count' => null,
                'error' => $errorMsg,
            ];
            @file_put_contents($logFile, json_encode($logRow, JSON_UNESCAPED_UNICODE) . PHP_EOL, FILE_APPEND | LOCK_EX);
            if (is_resource($verboseFile)) { fclose($verboseFile); }
            curl_close($curl);
            return null;
        } else {
            // Cevabı ham olarak da kaydet (güvenlik için ilk 4KB)
            $rawPath = Yii::getAlias('@app/runtime/dia_fatura_raw.txt');
            @file_put_contents($rawPath, json_encode([
                'ts' => date('c'), 'http' => $httpCode, 'dur_ms' => (int)round($duration*1000), 'body_snippet' => substr((string)$result, 0, 4096)
            ], JSON_UNESCAPED_UNICODE) . PHP_EOL, FILE_APPEND | LOCK_EX);

            $decoded = json_decode($result, true);
            $count = null;
            $status = 'ok';
            if (is_array($decoded) && isset($decoded['result']) && is_array($decoded['result'])) {
                $count = count($decoded['result']);
                if ($count === 0) {
                    $status = 'empty';
                }
            } elseif (is_array($decoded)) {
                $count = count($decoded);
            } else {
                $status = 'error';
            }
            $logRow = [
                'ts' => date('c'),
                'op' => 'faturaListele',
                'start' => $startDate,
                'end' => $endDate,
                'http' => $httpCode,
                'dur_ms' => (int)round($duration * 1000),
                'status' => $status,
                'count' => $count,
                'error' => null,
            ];
            @file_put_contents($logFile, json_encode($logRow, JSON_UNESCAPED_UNICODE) . PHP_EOL, FILE_APPEND | LOCK_EX);
            if (is_resource($verboseFile)) { fclose($verboseFile); }
            curl_close($curl);
            if ($raw) {
                if (empty($decoded['result'])) {
                    return false;
                }
                return $result;
            }
            return $decoded["result"] ?? null;
        }
    }
    public static function faturaListeleayrintili($startDate,$endDate, $raw=false){
        if($startDate==null){
            $startDate = date('Y-m-d', strtotime('-1 day'));
        }
        if($endDate==null){
            $endDate = date('Y-m-d');
        }
        
        // Tarih formatını basitleştir - direkt string olarak kullan
        $startDateFormatted = $startDate;
        $endDateFormatted = $endDate;
        
        $url = self::getDiaUrl('scf');
        $session_id = Dia::getsessionid();
        $firma_kodu = 1;
        $donem_kodu = 1;
 
        $data = [
            "scf_fatura_listele_ayrintili" => [
                "session_id" => $session_id,
                "firma_kodu" => $firma_kodu,
                "donem_kodu" => $donem_kodu,
                "filters" => [
                    ["field" => "tarih", "operator" => ">=", "value" => $startDateFormatted],
                    ["field" => "tarih", "operator" => "<=", "value" => $endDateFormatted],
                    ["field" => "turu", "operator" => "IN", "value" => "1,2,3"]
                ],
                "sorts" => "",
                "params" => "",
                "offset" => 0,
                "limit" => 30000,
            ]
        ];

        // Sade JSON log için tek dosya
        $logFile = Yii::getAlias('@app/runtime/dia_api.log');

        $jsonData = json_encode($data);
        $curl = curl_init();
        curl_setopt($curl, CURLOPT_URL, $url);
        curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($curl, CURLOPT_POSTFIELDS, $jsonData);
        curl_setopt($curl, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'Content-Length: ' . strlen($jsonData)
        ]);
        curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);
        // Timeout ayarları ekle
        curl_setopt($curl, CURLOPT_TIMEOUT, 120); // 2 dakika
        curl_setopt($curl, CURLOPT_CONNECTTIMEOUT, 30); // 30 saniye bağlantı timeout
        if (defined('CURLOPT_TCP_KEEPALIVE')) {
            curl_setopt($curl, CURLOPT_TCP_KEEPALIVE, 1);
            curl_setopt($curl, CURLOPT_TCP_KEEPIDLE, 20);
            curl_setopt($curl, CURLOPT_TCP_KEEPINTVL, 15);
        }
        $verboseFile = fopen(Yii::getAlias('@app/runtime/dia_curl_verbose.log'), 'a');
        curl_setopt($curl, CURLOPT_VERBOSE, true);
        curl_setopt($curl, CURLOPT_STDERR, $verboseFile);

        $execStart = microtime(true);
        $result = curl_exec($curl);
        $execEnd = microtime(true);
        $duration = round($execEnd - $execStart, 3);
        $info = curl_getinfo($curl);
        $httpCode = isset($info['http_code']) ? $info['http_code'] : 0;
        $transportInfoPath = Yii::getAlias('@app/runtime/dia_curl_info_fatura_kalem.txt');
        @file_put_contents($transportInfoPath, json_encode([
            'ts' => date('c'),
            'op' => 'faturaListeleAyrintili',
            'http' => $httpCode,
            'info' => $info,
            'request' => $data,
            'duration' => $duration
        ], JSON_UNESCAPED_UNICODE) . PHP_EOL, FILE_APPEND | LOCK_EX);

        if (curl_errno($curl)) {
            $error = curl_error($curl);
            $logRow = [
                'ts' => date('c'),
                'op' => 'faturaListeleAyrintili',
                'start' => $startDate,
                'end' => $endDate,
                'http' => $httpCode,
                'dur_ms' => (int)round($duration * 1000),
                'status' => 'error',
                'count' => null,
                'error' => $error,
            ];
            @file_put_contents($logFile, json_encode($logRow, JSON_UNESCAPED_UNICODE) . PHP_EOL, FILE_APPEND | LOCK_EX);
            if (is_resource($verboseFile)) { fclose($verboseFile); }
            curl_close($curl);
            return null;
        } else {
            $rawPath = Yii::getAlias('@app/runtime/dia_fatura_kalem_raw.txt');
            @file_put_contents($rawPath, json_encode([
                'ts' => date('c'), 'http' => $httpCode, 'dur_ms' => (int)round($duration*1000), 'body_snippet' => substr((string)$result, 0, 4096)
            ], JSON_UNESCAPED_UNICODE) . PHP_EOL, FILE_APPEND | LOCK_EX);

            $decoded = json_decode($result, true);
            $count = null;
            $status = 'ok';
            if (is_array($decoded) && isset($decoded['result']) && is_array($decoded['result'])) {
                $count = count($decoded['result']);
                if ($count === 0) {
                    $status = 'empty';
                }
            } elseif (is_array($decoded)) {
                $count = count($decoded);
            } else {
                $status = 'error';
            }
            $logRow = [
                'ts' => date('c'),
                'op' => 'faturaListeleAyrintili',
                'start' => $startDate,
                'end' => $endDate,
                'http' => $httpCode,
                'dur_ms' => (int)round($duration * 1000),
                'status' => $status,
                'count' => $count,
                'error' => null,
            ];
            @file_put_contents($logFile, json_encode($logRow, JSON_UNESCAPED_UNICODE) . PHP_EOL, FILE_APPEND | LOCK_EX);
            if (is_resource($verboseFile)) { fclose($verboseFile); }
            curl_close($curl);
            if ($raw) {
                if (empty($decoded['result'])) {
                    return false;
                }
                return $result;
            }
            return $decoded["result"] ?? null; 
        }
    }
    public static function siparisgonder($fis, $session_id = null, $tur = 1){
        $logFile = Yii::getAlias('@runtime/logs/siparisgonder_critical.log');

        try {
            $mainOrder = null;
            $satirlar = [];
            $carikart_kodu = null;
            $fisno = null;
            $api_turu = 0;
            $item_class_name = '';

            if ($tur == 1) { // Satınalma Siparişi
                $mainOrder = $fis->satinalmasiparisfis;
                $satirlar = $fis->getSatinAlmaSiparisFisSatirs()->andWhere(['>', 'miktar', 0])->with('urun')->all();
                $carikart_kodu = $fis->tedarikci->tedarikci_kodu;
                $fisno = $fis->fisno;
                $api_turu = 1;
                $item_class_name = \app\models\SatinAlmaSiparisFisSatir::class;
            } elseif ($tur == 2) { // Satış Fişi
                $mainOrder = $fis;
                $satirlar = $fis->getSalesReceiptItem()->andWhere(['>', 'miktar', 0])->with('urun')->all();
                $carikart_kodu = $fis->customer_code;
                $fisno = $fis->so_id;
                $api_turu = 2; // DIA'da satış siparişi türü (varsayım)
                $item_class_name = \app\models\SalesReceiptItem::class;
            } else {
                throw new \InvalidArgumentException("Geçersiz sipariş türü: $tur");
            }
            
            if (empty($satirlar)) {
                $errorMsg = "Siparişte miktarı 0'dan büyük olan ürün bulunamadı. Sipariş gönderimi iptal edildi. FisNo: $fisno";
                file_put_contents($logFile, "[".date('Y-m-d H:i:s')."] UYARI: $errorMsg\n", FILE_APPEND | LOCK_EX);
                return ['success' => false, 'message' => $errorMsg];
            }

            if (empty($carikart_kodu)) {
                $errorMsg = "Cari kart kodu (tedarikçi/müşteri) bulunamadı. Sipariş gönderimi iptal edildi. FisNo: $fisno";
                file_put_contents($logFile, "[".date('Y-m-d H:i:s')."] HATA: $errorMsg\n", FILE_APPEND | LOCK_EX);
                return ['success' => false, 'message' => $errorMsg];
            }

            $url = self::getDiaUrl('scf');
            if ($session_id === null) {
                $session_id = Dia::getsessionid();
            }

            $branchCode = Warehouses::find()->select(["branch_code"])->where(["warehouse_code" => $mainOrder->warehouse_code])->scalar();
            
            $sira = 1;
            $kalemler = [];
            foreach ($satirlar as $satir) {
                if (!$satir->urun) {
                    continue; // İlişkili ürün yoksa atla
                }
                $stok = $satir->urun;
                $stno = $stok->StokKodu;
                $birimAlani = $satir->birim;

                $birimkey = null;
                $birimAlaniNormalized = strtoupper(trim((string)$birimAlani));

                if ($birimAlaniNormalized === 'BOX') {
                    $birimkey = $stok->BirimKey2;
                } elseif ($birimAlaniNormalized === 'PACK') {
                    $birimkey = $stok->BirimKey3;
                } else { // 'UNIT' or empty/unknown, default to BirimKey1
                    $birimkey = $stok->BirimKey1;
                }
                
                if (in_array($birimAlaniNormalized, ['BOX', 'PACK']) && empty($birimkey)) {
                    $errorMsg = "HATA: '{$birimAlaniNormalized}' birimi seçildi ancak Urunler tablosunda karşılık gelen BirimKey tanımı eksik (StokKodu: {$stok->StokKodu}). FisNo: $fisno";
                    throw new \Exception($errorMsg);
                }

                if (empty($birimkey)) {
                    $errorMsg = "KRİTİK HATA: Ürün için hiçbir geçerli BirimKey bulunamadı (StokKodu: {$stok->StokKodu}). FisNo: $fisno";
                    throw new \Exception($errorMsg);
                }

                $sd = [
                    "_key_kalemturu" => ["stokkartkodu" => $stno],
                    "_key_scf_kalem_birimleri" => (int)$birimkey,
                    "_key_sis_depo_source" => ["depokodu" => $mainOrder->warehouse_code],
                    "_key_sis_doviz" => ["adi" => "GBP"],
                    "anamiktar" => number_format($satir->miktar ?? 0, 6, '.', ''),
                    "birimfiyati" => number_format($satir->BirimFiyat ?? 0, 6, '.', ''),
                    "daraadet" => "0.000000",
                    "dovizkuru" => "1.000000",
                    "indirim1" => "0.000000",
                    "indirim2" => "0.000000",
                    "indirim3" => "0.000000",
                    "indirim4" => "0.000000",
                    "indirim5" => "0.000000",
                    "indirimtoplam" => "0.000000",
                    "indirimtutari" => number_format($satir->retro ?? 0, 6, '.', ''),
                    "kalemturu" => "MLZM",
                    "kdv" => number_format($stok->Vat ?? 0, 6, '.', ''),
                    "kdvdurumu" => "H",
                    "kdvtutari" => "0.000000",
                    "miktar" => number_format($satir->miktar ?? 0, 6, '.', ''),
                    "note" => "",
                    "note2" => "",
                    "onay" => "KABUL",
                    "rezervasyon" => "H",
                    "siptarih" => $mainOrder->tarih,
                    "sirano" => $sira,
                    "sonbirimfiyati" => number_format($satir->BirimFiyat ?? 0, 6, '.', ''),
                    "teslimattarihi" => null,
                    "tutari" => "0.000000",
                    "yerelbirimfiyati" => number_format($satir->BirimFiyat ?? 0, 6, '.', ''),
                    "m_varyantlar" => []
                ];
                $kalemler[] = $sd;
                $sira++;
            }
            
            $data = [
                "scf_siparis_ekle" => [
                    "session_id" => $session_id,
                    "firma_kodu" => 1,
                    "donem_kodu" => 1,
                    "kart" => [
                        "_key_sis_sube_source" => ["subekodu" => $branchCode],
                        "_key_scf_carikart" => ["carikartkodu" => $carikart_kodu],
                        "_key_sis_depo_source" => ["depokodu" => $mainOrder->warehouse_code],
                        "_key_sis_doviz" => ["adi" => "GBP"],
                        "_key_sis_doviz_raporlama" => ["adi" => "GBP"],
                        "_key_sis_ozelkod1" => 0,
                        "_key_sis_ozelkod2" => 0,
                        "_key_sis_sube_source" => ["subekodu" => (string)$branchCode],
                        "aciklama1" => "",
                        "aciklama2" => "",
                        "aciklama3" => "",
                        "belgeno" => "",
                        "dovizkuru" => "1.000000",
                        "ekalan1" => "",
                        "fisno" => $fisno,
                        "m_kalemler" => $kalemler,
                        "net" => "0.000000",
                        "netdvz" => "0.000000",
                        "odemeislemli" => "f",
                        "odemeli" => "f",
                        "onay" => "KABUL",
                        "ortalamavade" => $mainOrder->tarih,
                        "raporlamadovizkuru" => "1.000000",
                        "saat" => date("H:i:s"),
                        "tarih" => date("Y-m-d"),
                        "teslimat_adres1" => "",
                        "teslimat_adres2" => "",
                        "teslimat_adsoyad" => "",
                        "teslimat_ceptel" => "",
                        "teslimat_ilce" => "",
                        "teslimat_key_sis_sehirler" => 0,
                        "teslimat_telefon" => "",
                        "toplam" => "00.000000",
                        "toplamdvz" => "0.000000",
                        "toplamindirim" => "0.000000",
                        "toplamindirimdvz" => "0.000000",
                        "toplamkdv" => "0.000000",
                        "toplamkdvdvz" => "0.000000",
                        "toplammasraf" => "0.000000",
                        "toplammasrafdvz" => "0.000000",
                        "turu" => $api_turu
                    ]
                ]
            ];
            
            $jsonData = json_encode($data);
            
            $curl = curl_init();
            curl_setopt($curl, CURLOPT_URL,  $url);
            curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
            curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($curl, CURLOPT_POSTFIELDS, $jsonData);
            curl_setopt($curl, CURLOPT_HTTPHEADER, [
                'Content-Type: application/json',
                'Content-Length: ' . strlen($jsonData)
            ]);
            curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);
            
            $result = curl_exec($curl);
            
            if (curl_errno($curl)) {
                $errorMsg = 'cURL hatası: ' . curl_error($curl);
                throw new \Exception($errorMsg);
            }
            
            $json = json_decode($result, true);
            
            if (isset($json['code']) && $json['code'] != '200' && $json['code'] != 200) {
                $errorMsg = $json['msg'] ?? 'Bilinmeyen API hatası';
                $errorMsg = "API Hatası (Code: {$json['code']}): $errorMsg. FisNo: $fisno";
                throw new \Exception($errorMsg);
            }
            
            $returnedFisno = $json['extra']['fisno'] ?? null;
            curl_close($curl);
            return ['success' => true, 'fisno' => $returnedFisno];

        } catch (\Exception $e) {
            $hataMesaji = 'siparisgonder HATA: ' . $e->getMessage() . ' - ' . date('Y-m-d H:i:s') . PHP_EOL;
            file_put_contents($logFile, $hataMesaji, FILE_APPEND | LOCK_EX);
            if (isset($curl) && is_resource($curl)) {
                curl_close($curl);
            }
            return ['success' => false, 'message' => $e->getMessage()];
        }
    }

    public static function goodReceiptIrsaliyeEkle($fis,$kalemler)
    {
        
    
        $url = self::getDiaUrl('scf');
        $session_id = Dia::getsessionid();

        $firma_kodu = 1;
        $donem_kodu = 1;
        
        $sira=0;
        $tumkalemler=[];
        
        
        foreach($kalemler as $k){
            // urun_key kullan (veritabanında bu şekilde tanımlı)
            $urun=Urunler::find()->where(["_key"=>$k->urun_key])->one();
            $sira++;
            if($urun){
                // birim_key direkt kullanılıyor
                $unitKey = $k->birim_key ?? null;
                
                if(!$unitKey) {
                    $errorMsg = "Unit key bulunamadı. Receipt item: " . $k->id . 
                        ", urun_key: " . $k->urun_key . 
                        ", birim_key: " . ($k->birim_key ?? 'null');
                    Yii::error($errorMsg, __METHOD__);
                    throw new \Exception($errorMsg);
                }
                
                $kalem= [
                    "_key_kalemturu" => $urun->_key, // DIA bu alanı zorunlu istiyor
                    "_key_scf_stokkart" => ["stokkodu" => $urun->StokKodu], // Stok kartı referansı
                    "_key_scf_kalem_birimleri" => $unitKey,
                    "_key_sis_depo_source" => $fis->warehouse->_key,
                    "_key_sis_doviz" => ["adi" => "GBP"],
                    "anamiktar" => floatval($k->quantity_received),
                    "dovizkuru" => "1.000000",
                    "irstarih" => date("Y-m-d"),
                    "kalemturu" => "MLZM",
                    "miktar" => floatval($k->quantity_received),
                    "note" => "",
                    "note2" => "",
                    "ovkdvoran" => "E",
                    "ovkdvtutar" => "E",
                    "ovmanuel" => "H",
                    "ozelalanf" => "",
                    "promosyonkalemid" => "",
                    "sirano" => $sira
                ];
                
                // siparis_key varsa ekle
                if(!empty($k->siparis_key)) {
                    $kalem["_key_scf_siparis_kalemi"] = $k->siparis_key;
                }
                
                $kalem["m_varyantlar"] = [];
                $tumkalemler[] = $kalem; // $kalem tanımlı olduğundan emin olduktan sonra ekle
            }
        }
        
       
        // Warehouse ve branch kontrolü
        if (!$fis->warehouse || !$fis->warehouse->_key) {
            $errorMsg = "Warehouse bilgisi bulunamadı veya _key değeri eksik. Receipt ID: " . $fis->goods_receipt_id;
            Yii::error($errorMsg, __METHOD__);
            throw new \Exception($errorMsg);
        }
        
        if (!$fis->warehouse->branch || !$fis->warehouse->branch->_key) {
            $errorMsg = "Branch bilgisi bulunamadı veya _key değeri eksik. Warehouse: " . $fis->warehouse->warehouse_code;
            Yii::error($errorMsg, __METHOD__);
            throw new \Exception($errorMsg);
        }

        // Cari kodu belirle
        $carikod = "C00000001";
        if($fis->siparis && isset($fis->siparis->__carikodu) && !empty($fis->siparis->__carikodu)) {
            $carikod = $fis->siparis->__carikodu;
        }
    
    
        $data = [
            "scf_irsaliye_ekle" => [
                "session_id" => $session_id,
                "firma_kodu" => $firma_kodu,
                "donem_kodu" => $donem_kodu,
                "kart" => [
                    "_key_scf_carikart" => ["carikartkodu" => $carikod],
                    "_key_sis_depo_source" => $fis->warehouse->_key,
                    "_key_sis_doviz" => ["adi" => "GBP"],
                    "_key_sis_doviz_raporlama" => ["adi" => "GBP"],
                    "_key_sis_sube_source" => $fis->warehouse->branch->_key,
                    "belgeno" => "000009",
                    "belgeno2" => "WS000001",
                    "dovizkuru" => "1.000000",
                    "fisno" => "WS00001",
                    "karsifirma" => "C",
                    "m_kalemler" => $tumkalemler,
                    "raporlamadovizkuru" => "1.000000",
                    "saat" => date("H:i:s"),
                    "tarih" => date("Y-m-d"),
                    "turu" => 1
                ]
            ]
        ];
       

        $jsonData = json_encode($data);

        // Debug: Gönderilen veriyi logla
        Yii::info("DIA'ya gönderilen JSON: " . $jsonData, __METHOD__);
     
        $curl = curl_init();
        curl_setopt($curl, CURLOPT_URL, $url);
        curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($curl, CURLOPT_POSTFIELDS, $jsonData);
        curl_setopt($curl, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'Content-Length: ' . strlen($jsonData)
        ]);
        curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);

        $result = curl_exec($curl);

        if (curl_errno($curl)) {
            $error = curl_error($curl);
            curl_close($curl);
            $hataMesaji = 'cURL hatası: ' . $error . ' - ' . date('Y-m-d H:i:s') . PHP_EOL;
            file_put_contents('runtime/curl_hatalari.txt', $hataMesaji, FILE_APPEND | LOCK_EX);
            Yii::error("DIA cURL hatası: " . $error, __METHOD__);
            return null;
        } else {
            curl_close($curl);
            $json = json_decode($result, true);
            
            // Debug için DIA yanıtını logla
            Yii::info("DIA İrsaliye Ekleme Yanıtı: " . json_encode($json), __METHOD__);
            
            // Başarılı/başarısız durumu kontrol et
            if(isset($json['code'])) {
                if($json['code'] == '200') {
                    Yii::info("DIA İrsaliye başarıyla eklendi. Key: " . ($json['key'] ?? 'N/A'), __METHOD__);
                } else {
                    Yii::error("DIA İrsaliye eklenemedi. Hata: " . ($json['msg'] ?? 'Bilinmeyen hata'), __METHOD__);
                }
            }
            
            return $json;
        }
    }

    public static function sayimfisi_ekle($depo_key, $fisno)
    {
        $url = self::getDiaUrl('scf');
        $ssid = Dia::getsessionid();
        $tarih = date('Y-m-d');

        $data = [
            "scf_sayimfisi_ekle" => [
                "session_id" => $ssid,
                "firma_kodu" => 1,
                "donem_kodu" => 1,
                "kart" => [
                    "_key_sis_depo" => (int)$depo_key,
                    "aciklama"      => "Depo Sayımı (WS)",
                    "durum"         => "1",
                    "farkmiktarturu" => "fiili_stok",
                    "fisno"         => $fisno,
                    "tarih"         => $tarih
                ]
            ]
        ];

        $jsonData = json_encode($data);

        $logMessage = "=== DIA::sayimfisi_ekle BAŞLADI ===\n";
        $logMessage .= "Tarih: " . date('Y-m-d H:i:s') . "\n";
        $logMessage .= "Depo Key: " . $depo_key . "\n";
        $logMessage .= "Fisno: " . $fisno . "\n";
        $logMessage .= "URL: " . $url . "\n";
        $logMessage .= "JSON Data: " . $jsonData . "\n";

        $curl = curl_init();
        curl_setopt($curl, CURLOPT_URL, $url);
        curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($curl, CURLOPT_POSTFIELDS, $jsonData);
        curl_setopt($curl, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'Content-Length: ' . strlen($jsonData)
        ]);
        curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($curl, CURLOPT_TIMEOUT, 120);
        curl_setopt($curl, CURLOPT_CONNECTTIMEOUT, 30);

        $result = curl_exec($curl);
        $httpCode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
        $curlError = curl_error($curl);
        $curlErrno = curl_errno($curl);

        $logMessage .= "cURL HTTP Code: " . $httpCode . "\n";
        $logMessage .= "cURL Error No: " . $curlErrno . "\n";
        $logMessage .= "cURL Error: " . $curlError . "\n";
        $logMessage .= "cURL Response: " . $result . "\n";

        $sonuc = null;
        if ($curlErrno) {
            $hataMesaji = 'cURL hatası: ' . $curlError . ' - ' . date('Y-m-d H:i:s') . PHP_EOL;
            file_put_contents(\Yii::getAlias('@runtime/curl_hatalari.txt'), $hataMesaji, FILE_APPEND | LOCK_EX);
            $logMessage .= "cURL hatası tespit edildi ve curl_hatalari.txt'ye yazıldı\n";
            $sonuc = ['code' => $curlErrno, 'hata' => $curlError];
        } else {
            $json = json_decode($result, true);
            $logMessage .= "JSON decode başarılı: " . (is_array($json) ? 'Evet' : 'Hayır') . "\n";
            if (is_array($json)) {
                $logMessage .= "JSON Response: " . print_r($json, true) . "\n";
            }
            $sonuc = $json;
        }

        curl_close($curl);
        $logMessage .= "cURL kapatıldı\n";
        $logMessage .= "=== DIA::sayimfisi_ekle TAMAMLANDI ===\n\n";

        file_put_contents(\Yii::getAlias('@runtime/dia_sayim_log.txt'), $logMessage, FILE_APPEND | LOCK_EX);

        return $sonuc;
    }

    public static function sayimfisi_kalem_ekle($sayimfisi_key, $_key_stokkart, $_key_stokkart_birim, $sayim_miktar, $_key_rafyeri = null){
        $url = self::getDiaUrl('scf');
        $ssid = Dia::getsessionid();

        $kartData = [
            "_key_scf_sayimfisi" => (int)$sayimfisi_key,
            "_key_scf_stokkart" => (int)$_key_stokkart,
            "_key_scf_stokkart_birimleri" => (int)$_key_stokkart_birim,
            "sayimmiktari" => (string)$sayim_miktar,
        ];

        if ($_key_rafyeri !== null) {
            $kartData["_key_scf_rafyeri"] = (int)$_key_rafyeri;
        }

        $data = [
            "scf_sayimfisi_kalemi_ekle" => [
                "session_id" => $ssid,
                "firma_kodu" => 1,
                "donem_kodu" => 1,
                "kart" => $kartData
            ]
        ];

        $jsonData = json_encode($data);

        $logMessage = "=== DIA::sayimfisi_kalem_ekle BAŞLADI ===\n";
        $logMessage .= "Tarih: " . date('Y-m-d H:i:s') . "\n";
        $logMessage .= "Sayım Fişi Key: " . $sayimfisi_key . "\n";
        $logMessage .= "Stok Kart Key: " . $_key_stokkart . "\n";
        $logMessage .= "Stok Birim Key: " . $_key_stokkart_birim . "\n";
        $logMessage .= "Sayım Miktarı: " . $sayim_miktar . "\n";
        $logMessage .= "Raf Yeri Key: " . $_key_rafyeri . "\n";
        $logMessage .= "URL: " . $url . "\n";
        $logMessage .= "JSON Data: " . $jsonData . "\n";

        $curl = curl_init();
        curl_setopt($curl, CURLOPT_URL, $url);
        curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($curl, CURLOPT_POSTFIELDS, $jsonData);
        curl_setopt($curl, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'Content-Length: ' . strlen($jsonData)
        ]);
        curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($curl, CURLOPT_TIMEOUT, 120);
        curl_setopt($curl, CURLOPT_CONNECTTIMEOUT, 30);

        $result = curl_exec($curl);
        $httpCode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
        $curlError = curl_error($curl);
        $curlErrno = curl_errno($curl);

        $logMessage .= "cURL HTTP Code: " . $httpCode . "\n";
        $logMessage .= "cURL Error No: " . $curlErrno . "\n";
        $logMessage .= "cURL Error: " . $curlError . "\n";
        $logMessage .= "cURL Response: " . $result . "\n";

        $sonuc = null;
        if ($curlErrno) {
            $hataMesaji = 'cURL hatası: ' . $curlError . ' - ' . date('Y-m-d H:i:s') . PHP_EOL;
            file_put_contents(\Yii::getAlias('@runtime/curl_hatalari.txt'), $hataMesaji, FILE_APPEND | LOCK_EX);
            $logMessage .= "cURL hatası tespit edildi ve curl_hatalari.txt'ye yazıldı\n";
            $sonuc = ['code' => $curlErrno, 'hata' => $curlError];
        } else {
            $json = json_decode($result, true);
            $logMessage .= "JSON decode başarılı: " . (is_array($json) ? 'Evet' : 'Hayır') . "\n";
            if (is_array($json)) {
                $logMessage .= "JSON Response: " . print_r($json, true) . "\n";
            }
            $sonuc = $json;
        }

        curl_close($curl);
        $logMessage .= "cURL kapatıldı\n";
        $logMessage .= "=== DIA::sayimfisi_kalem_ekle TAMAMLANDI ===\n\n";

        file_put_contents(\Yii::getAlias('@runtime/dia_sayim_log.txt'), $logMessage, FILE_APPEND | LOCK_EX);

        return $sonuc;
    }

    public static function sayimfisi_kapat($sayimfisi_key)
    {
        $url = self::getDiaUrl('scf');
        $ssid = Dia::getsessionid();

        $data = [
            "scf_sayimfisi_kapat" => [
                "session_id" => $ssid,
                "firma_kodu" => 1,
                "donem_kodu" => 1,
                "params" => [
                    "_key" => (int)$sayimfisi_key,
                    "fiyatturu" => "eldo",
                    "sairfislerikullan" => false
                ]
            ]
        ];

        $jsonData = json_encode($data);

        $logMessage = "=== DIA::sayimfisi_kapat BAŞLADI ===\n";
        $logMessage .= "Tarih: " . date('Y-m-d H:i:s') . "\n";
        $logMessage .= "Sayım Fişi Key: " . $sayimfisi_key . "\n";
        $logMessage .= "URL: " . $url . "\n";
        $logMessage .= "JSON Data: " . $jsonData . "\n";

        $curl = curl_init();
        curl_setopt($curl, CURLOPT_URL, $url);
        curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($curl, CURLOPT_POSTFIELDS, $jsonData);
        curl_setopt($curl, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'Content-Length: ' . strlen($jsonData)
        ]);
        curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($curl, CURLOPT_TIMEOUT, 120);
        curl_setopt($curl, CURLOPT_CONNECTTIMEOUT, 30);

        $result = curl_exec($curl);
        $httpCode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
        $curlError = curl_error($curl);
        $curlErrno = curl_errno($curl);

        $logMessage .= "cURL HTTP Code: " . $httpCode . "\n";
        $logMessage .= "cURL Error No: " . $curlErrno . "\n";
        $logMessage .= "cURL Error: " . $curlError . "\n";
        $logMessage .= "cURL Response: " . $result . "\n";

        $sonuc = null;
        if ($curlErrno) {
            $hataMesaji = 'cURL hatası: ' . $curlError . ' - ' . date('Y-m-d H:i:s') . PHP_EOL;
            file_put_contents(\Yii::getAlias('@runtime/curl_hatalari.txt'), $hataMesaji, FILE_APPEND | LOCK_EX);
            $logMessage .= "cURL hatası tespit edildi ve curl_hatalari.txt'ye yazıldı\n";
            $sonuc = ['code' => $curlErrno, 'hata' => $curlError];
        } else {
            $json = json_decode($result, true);
            $logMessage .= "JSON decode başarılı: " . (is_array($json) ? 'Evet' : 'Hayır') . "\n";
            if (is_array($json)) {
                $logMessage .= "JSON Response: " . print_r($json, true) . "\n";
            }
            $sonuc = $json;
        }

        curl_close($curl);
        $logMessage .= "cURL kapatıldı\n";
        $logMessage .= "=== DIA::sayimfisi_kapat TAMAMLANDI ===\n\n";

        file_put_contents(\Yii::getAlias('@runtime/dia_sayim_log.txt'), $logMessage, FILE_APPEND | LOCK_EX);

        return $sonuc;
    }

    public static function rafyeri_gonder($shelf_code, $warehouse_key)
    {
        $url = self::getDiaUrl('scf');
        $ssid = Dia::getsessionid();
        $firma_kodu = 1;
        $donem_kodu = 1;

        $data = [
            "scf_rafyeri_ekle" => [
                "session_id" => $ssid,
                "firma_kodu" => $firma_kodu,
                "donem_kodu" => $donem_kodu,
                "kart" => [
                    "_key_sis_depo" => (int)$warehouse_key,
                    "aciklama"      => (string)$shelf_code,
                    "durum"         => "A",
                    "kod"           => (string)$shelf_code,
                    "en"            => "0",
                    "boy"           => "0",
                    "maxnetagirlik" => "0",
                    "maxdesi"       => "0",
                    "dolulukdurumu" => "A",
                    "bolge"         => ""
                ]
            ]
        ];

        $jsonData = json_encode($data);

        $logMessage = "=== DIA::rafyeri_gonder BAŞLADI ===\n";
        $logMessage .= "Tarih: " . date('Y-m-d H:i:s') . "\n";
        $logMessage .= "Warehouse Key: " . $warehouse_key . "\n";
        $logMessage .= "Shelf Code: " . $shelf_code . "\n";
        $logMessage .= "URL: " . $url . "\n";
        $logMessage .= "JSON Data: " . $jsonData . "\n";

        $curl = curl_init();
        curl_setopt($curl, CURLOPT_URL, $url);
        curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($curl, CURLOPT_POSTFIELDS, $jsonData);
        curl_setopt($curl, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'Content-Length: ' . strlen($jsonData)
        ]);
        curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($curl, CURLOPT_TIMEOUT, 60);
        curl_setopt($curl, CURLOPT_CONNECTTIMEOUT, 15);

        $result = curl_exec($curl);
        $httpCode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
        $curlError = curl_error($curl);
        $curlErrno = curl_errno($curl);

        $logMessage .= "cURL HTTP Code: " . $httpCode . "\n";
        $logMessage .= "cURL Error No: " . $curlErrno . "\n";
        $logMessage .= "cURL Error: " . $curlError . "\n";
        $logMessage .= "cURL Response: " . $result . "\n";

        $sonuc = null;
        if ($curlErrno) {
            $hataMesaji = 'cURL hatası: ' . $curlError . ' - ' . date('Y-m-d H:i:s') . PHP_EOL;
            file_put_contents(\Yii::getAlias('@runtime/curl_hatalari.txt'), $hataMesaji, FILE_APPEND | LOCK_EX);
            $logMessage .= "cURL hatası tespit edildi ve curl_hatalari.txt'ye yazıldı\n";
            $sonuc = ['code' => $curlErrno, 'hata' => $curlError];
        } else {
            $json = json_decode($result, true);
            $logMessage .= "JSON decode başarılı: " . (is_array($json) ? 'Evet' : 'Hayır') . "\n";
            if (is_array($json)) {
                $logMessage .= "JSON Response: " . print_r($json, true) . "\n";
            }
            $sonuc = $json;
        }

        curl_close($curl);
        $logMessage .= "cURL kapatıldı\n";
        $logMessage .= "=== DIA::rafyeri_gonder TAMAMLANDI ===\n\n";

        file_put_contents(\Yii::getAlias('@runtime/dia_rafyeri_log.txt'), $logMessage, FILE_APPEND | LOCK_EX);

        return $sonuc;
    }

    public static function rafyeri_listele()
    {
        $url = self::getDiaUrl('scf');
        $session_id = Dia::getsessionid();
        $firma_kodu = 1;
        $donem_kodu = 1;

        $data = [
            "scf_rafyeri_listele" => [
                "session_id" => $session_id,
                "firma_kodu" => $firma_kodu,
                "donem_kodu" => $donem_kodu,
                "filters" => "",
                "sorts" => "",
                "params" => "",
                "limit" => 30000,
                "offset" => 0
            ]
        ];

        $jsonData = json_encode($data);
        $curl = curl_init();
        curl_setopt($curl, CURLOPT_URL, $url);
        curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($curl, CURLOPT_POSTFIELDS, $jsonData);
        curl_setopt($curl, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'Content-Length: ' . strlen($jsonData)
        ]);
        curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($curl, CURLOPT_TIMEOUT, 180); // 3 minutes
        curl_setopt($curl, CURLOPT_CONNECTTIMEOUT, 45);

        $result = curl_exec($curl);
        
        if (curl_errno($curl)) {
            $errorMsg = curl_error($curl);
            Yii::error('Rafyeri listele cURL hatası: ' . $errorMsg, 'dia');
            curl_close($curl);
            return null;
        }

        curl_close($curl);
        $decoded = json_decode($result, true);

        return $decoded["result"] ?? null;
    }
    public static function irsaliyelistele($startDate,$endDate){
        if($startDate == null){
            $startDate = date('Y-m-d 00:00:00', strtotime('-1 day'));
        }
        if($endDate == null){
            $endDate = date('Y-m-d 23:59:59');
        }
        $url = self::getDiaUrl('scf');
        $session_id = Dia::getsessionid();
        $firma_kodu = 1;
        $donem_kodu = 1;

        $data = [
            "scf_irsaliye_listele" => [
                "session_id" => $session_id,
                "firma_kodu" => $firma_kodu,
                "donem_kodu" => $donem_kodu,
                "filters" => [
                    ["field" => "_cdate", "operator" => ">=", "value" => $startDate],
                    ["field" => "_cdate", "operator" => "<=", "value" => $endDate],
                ],
            ]
        ];

        $jsonData = json_encode($data);
        $curl = curl_init();
        curl_setopt($curl, CURLOPT_URL, $url);
        curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($curl, CURLOPT_POSTFIELDS, $jsonData);
        curl_setopt($curl, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'Content-Length: ' . strlen($jsonData)
        ]);
        curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($curl, CURLOPT_TIMEOUT, 120);
        curl_setopt($curl, CURLOPT_CONNECTTIMEOUT, 30);

        $result = curl_exec($curl);
        if (curl_errno($curl)) {
            Yii::error('İrsaliye listele cURL hatası: ' . curl_error($curl), 'dia');
            curl_close($curl);
            return null;
        } else {
            $json = json_decode($result, true);
            curl_close($curl);
            return $json['result'] ?? null;
        }
    }

    public static function irsaliyelisteleayrintili($startDate,$endDate){
        if($startDate == null){
            $startDate = date('Y-m-d 00:00:00', strtotime('-1 day'));
        }
        if($endDate == null){
            $endDate = date('Y-m-d 23:59:59');
        }
        $url = self::getDiaUrl('scf');
        $session_id = Dia::getsessionid();
        $firma_kodu = 1;
        $donem_kodu = 1;
 
        $data = [
            "scf_irsaliye_listele_ayrintili" => [
                "session_id" => $session_id,
                "firma_kodu" => $firma_kodu,
                "donem_kodu" => $donem_kodu,
                "filters" => [
                    ["field" => "_cdate", "operator" => ">=", "value" => $startDate],
                    ["field" => "_cdate", "operator" => "<=", "value" => $endDate],
                ],
            ]
        ];

        $jsonData = json_encode($data);
        $curl = curl_init();
        curl_setopt($curl, CURLOPT_URL, $url);
        curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($curl, CURLOPT_POSTFIELDS, $jsonData);
        curl_setopt($curl, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'Content-Length: ' . strlen($jsonData)
        ]);
        curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($curl, CURLOPT_TIMEOUT, 60);
        curl_setopt($curl, CURLOPT_CONNECTTIMEOUT, 15);

        $result = curl_exec($curl);
        
        if (curl_errno($curl)) {
            Yii::error('İrsaliye listele ayrıntılı cURL hatası: ' . curl_error($curl), 'dia');
            curl_close($curl);
            return null;
        } else {
            $json = json_decode($result, true);
            curl_close($curl);
            return $json['result'] ?? null;
        }
    }

    public static function irsaliyelisteleayrintilibykey($startDate, $endDate, $irsaliye_key){
        if($startDate == null){
            $startDate = date('Y-m-d 00:00:00', strtotime('-1 day'));
        }
        if($endDate == null){
            $endDate = date('Y-m-d 23:59:59');
        }
        $url = self::getDiaUrl('scf');
        $session_id = Dia::getsessionid();
        $firma_kodu = 1;
        $donem_kodu = 1;
 
        $data = [
            "scf_irsaliye_listele_ayrintili" => [
                "session_id" => $session_id,
                "firma_kodu" => $firma_kodu,
                "donem_kodu" => $donem_kodu,
                "filters" => [
                    ["field" => "_cdate", "operator" => ">=", "value" => $startDate],
                    ["field" => "_cdate", "operator" => "<=", "value" => $endDate],
                    ["field" => "_key_scf_irsaliye", "operator" => "=", "value" => $irsaliye_key],
                ],
            ]
        ];

        $jsonData = json_encode($data);
        $curl = curl_init();
        curl_setopt($curl, CURLOPT_URL, $url);
        curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "POST");
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($curl, CURLOPT_POSTFIELDS, $jsonData);
        curl_setopt($curl, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'Content-Length: ' . strlen($jsonData)
        ]);
        curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);
        // Timeout ayarları ekle
        curl_setopt($curl, CURLOPT_TIMEOUT, 60); // 1 dakika
        curl_setopt($curl, CURLOPT_CONNECTTIMEOUT, 15); // 15 saniye bağlantı timeout

        $result = curl_exec($curl);
        
        if (curl_errno($curl)) {
            $error = curl_error($curl);
            Yii::error('İrsaliye ayrıntı cURL hatası: ' . $error, 'dia');
            curl_close($curl);
            return null;
        } else {
            $json = json_decode($result, true);
            curl_close($curl);
            return $json['result'] ?? null;
        }
    }
}