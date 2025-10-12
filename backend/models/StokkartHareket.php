<?php

namespace app\models;

use Yii;
use yii\db\ActiveRecord;

/**
 * This is the model class for table "stokkart_hareket".
 *
 * @property int $id
 * @property string|null $_cdate
 * @property string|null $_date
 * @property string|null $_key
 * @property string|null $_key_fiskalemi
 * @property string|null $_key_scf_fatura
 * @property string|null $_key_scf_kasafisi
 * @property string|null $_key_sis_depo
 * @property string|null $_key_sis_doviz
 * @property string|null $_key_sis_seviyekodu
 * @property string|null $_key_sis_seviyekodu_cari
 * @property string|null $_level1
 * @property string|null $_level2
 * @property string|null $aciklama
 * @property float|null $anabirimfiyati
 * @property float|null $anamiktar
 * @property string|null $baglifaturaturu
 * @property string|null $belgeno
 * @property string|null $belgeno2
 * @property string|null $bilgi
 * @property string|null $birim
 * @property float|null $birimfiyati
 * @property float|null $birimfiyati_fisdovizi
 * @property string|null $carikodu
 * @property string|null $cariunvan
 * @property string|null $depo
 * @property string|null $depokodu
 * @property string|null $doviz
 * @property float|null $dovizkuru
 * @property string|null $ekleyenkullaniciadi
 * @property string|null $faturano
 * @property string|null $faturatarihi
 * @property string|null $fisdovizadi
 * @property float|null $fisdovizkuru
 * @property string|null $fisno
 * @property string|null $girismi
 * @property string|null $iadefisno
 * @property float|null $indirimtoplam
 * @property float|null $indirimtutari
 * @property string|null $iptalmi
 * @property string|null $karsidepoadi
 * @property float|null $kdv
 * @property string|null $kdvdurumu
 * @property float|null $kdvtutari
 * @property float|null $kmiktar
 * @property string|null $konsinyeurunfaturasi
 * @property string|null $kullaniciadi
 * @property float|null $miktar
 * @property string|null $muhasebelesme
 * @property string|null $note
 * @property string|null $ozelalan1
 * @property string|null $ozelalan2
 * @property string|null $ozelalan3
 * @property string|null $ozelalan4
 * @property string|null $ozelalan5
 * @property string|null $ozelkod
 * @property string|null $saat
 * @property string|null $satiselemani
 * @property float|null $sonbirimfiyati
 * @property float|null $sonbirimfiyati_fisdovizi
 * @property float|null $sonbirimfiyatkdvharic
 * @property float|null $sonbirimfiyatkdvharic_fisdovizi
 * @property string|null $sube
 * @property string|null $talepozelkodu
 * @property string|null $tarih
 * @property string|null $tip
 * @property string|null $turu
 * @property string|null $turuack
 * @property string|null $turuackkisa
 * @property float|null $tutari
 * @property float|null $tutari_fisdovizi
 * @property string|null $woturu
 */
class StokkartHareket extends ActiveRecord
{
    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'stokkart_hareket';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['_cdate', '_date', 'faturatarihi', 'tarih', 'saat'], 'safe'],
            [['aciklama', 'note', 'StokKodu'], 'string'],
            [['anabirimfiyati', 'anamiktar', 'birimfiyati', 'birimfiyati_fisdovizi', 'dovizkuru', 'fisdovizkuru', 'indirimtoplam', 'indirimtutari', 'kdv', 'kdvtutari', 'kmiktar', 'miktar', 'sonbirimfiyati', 'sonbirimfiyati_fisdovizi', 'sonbirimfiyatkdvharic', 'sonbirimfiyatkdvharic_fisdovizi', 'tutari', 'tutari_fisdovizi'], 'number'],
            [['_key', '_key_fiskalemi', '_key_scf_fatura', '_key_scf_kasafisi', '_key_sis_depo', '_key_sis_doviz', 'birim', 'depokodu', 'ozelalan1', 'ozelalan2', 'ozelalan3', 'ozelalan4', 'ozelalan5', 'tip'], 'string', 'max' => 20],
            [['_key_sis_seviyekodu', '_key_sis_seviyekodu_cari', 'baglifaturaturu', 'doviz', 'fisdovizadi', 'turu', 'woturu'], 'string', 'max' => 10],
            [['_level1', '_level2'], 'string', 'max' => 5],
            [['belgeno', 'belgeno2', 'faturano', 'fisno', 'iadefisno', 'ozelkod', 'talepozelkodu'], 'string', 'max' => 50],
            [['girismi', 'iptalmi', 'kdvdurumu', 'konsinyeurunfaturasi', 'muhasebelesme'], 'string', 'max' => 1],
            [['bilgi'], 'string', 'max' => 255],
            [['carikodu'], 'string', 'max' => 30],
            [['cariunvan'], 'string', 'max' => 255],
            [['depo', 'ekleyenkullaniciadi', 'karsidepoadi', 'kullaniciadi', 'satiselemani', 'sube', 'turuack', 'turuackkisa'], 'string', 'max' => 100],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => 'ID',
            '_cdate' => 'Oluşturulma Tarihi',
            '_date' => 'Tarih',
            '_key' => 'Anahtar',
            '_key_fiskalemi' => 'Fiş Kalemi Anahtarı',
            '_key_scf_fatura' => 'Fatura Anahtarı',
            '_key_scf_kasafisi' => 'Kasa Fişi Anahtarı',
            '_key_sis_depo' => 'Depo Anahtarı',
            '_key_sis_doviz' => 'Döviz Anahtarı',
            '_key_sis_seviyekodu' => 'Seviye Kodu Anahtarı',
            '_key_sis_seviyekodu_cari' => 'Cari Seviye Kodu Anahtarı',
            '_level1' => 'Seviye 1',
            '_level2' => 'Seviye 2',
            'aciklama' => 'Açıklama',
            'anabirimfiyati' => 'Ana Birim Fiyatı',
            'anamiktar' => 'Ana Miktar',
            'baglifaturaturu' => 'Bağlı Fatura Türü',
            'belgeno' => 'Belge No',
            'belgeno2' => 'Belge No 2',
            'bilgi' => 'Bilgi',
            'birim' => 'Birim',
            'birimfiyati' => 'Birim Fiyatı',
            'birimfiyati_fisdovizi' => 'Birim Fiyatı (Fiş Dövizi)',
            'carikodu' => 'Cari Kodu',
            'cariunvan' => 'Cari Ünvan',
            'depo' => 'Depo',
            'depokodu' => 'Depo Kodu',
            'doviz' => 'Döviz',
            'dovizkuru' => 'Döviz Kuru',
            'ekleyenkullaniciadi' => 'Ekleyen Kullanıcı Adı',
            'faturano' => 'Fatura No',
            'faturatarihi' => 'Fatura Tarihi',
            'fisdovizadi' => 'Fiş Döviz Adı',
            'fisdovizkuru' => 'Fiş Döviz Kuru',
            'fisno' => 'Fiş No',
            'girismi' => 'Giriş mi?',
            'iadefisno' => 'İade Fiş No',
            'indirimtoplam' => 'İndirim Toplam',
            'indirimtutari' => 'İndirim Tutarı',
            'iptalmi' => 'İptal mi?',
            'karsidepoadi' => 'Karşı Depo Adı',
            'kdv' => 'KDV',
            'kdvdurumu' => 'KDV Durumu',
            'kdvtutari' => 'KDV Tutarı',
            'kmiktar' => 'K Miktar',
            'konsinyeurunfaturasi' => 'Konsinye Ürün Faturası',
            'kullaniciadi' => 'Kullanıcı Adı',
            'miktar' => 'Miktar',
            'muhasebelesme' => 'Muhasebeleşme',
            'note' => 'Not',
            'ozelalan1' => 'Özel Alan 1',
            'ozelalan2' => 'Özel Alan 2',
            'ozelalan3' => 'Özel Alan 3',
            'ozelalan4' => 'Özel Alan 4',
            'ozelalan5' => 'Özel Alan 5',
            'ozelkod' => 'Özel Kod',
            'saat' => 'Saat',
            'satiselemani' => 'Satış Elemanı',
            'sonbirimfiyati' => 'Son Birim Fiyatı',
            'sonbirimfiyati_fisdovizi' => 'Son Birim Fiyatı (Fiş Dövizi)',
            'sonbirimfiyatkdvharic' => 'Son Birim Fiyat KDV Hariç',
            'sonbirimfiyatkdvharic_fisdovizi' => 'Son Birim Fiyat KDV Hariç (Fiş Dövizi)',
            'sube' => 'Şube',
            'talepozelkodu' => 'Talep Özel Kodu',
            'tarih' => 'Tarih',
            'tip' => 'Tip',
            'turu' => 'Türü',
            'turuack' => 'Türü Açıklama',
            'turuackkisa' => 'Türü Kısa Açıklama',
            'tutari' => 'Tutarı',
            'tutari_fisdovizi' => 'Tutarı (Fiş Dövizi)',
            'woturu' => 'WO Türü',
            'StokKodu' => 'Stok Kodu',
        ];
    }
} 