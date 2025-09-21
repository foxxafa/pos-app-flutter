<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "urunler".
 *
 * @property int $UrunId
 * @property string|null $StokKodu
 * @property string $UrunAdi
 * @property string|null $AdetFiyati
 * @property string|null $KutuFiyati
 * @property string|null $Pm1
 * @property string|null $Pm2
 * @property string|null $Pm3
 * @property string|null $Vat
 * @property string|null $Birim1
 * @property int|null $BirimKey1
 * @property string|null $Birim2
 * @property int|null $BirimKey2
 * @property string|null $Birim3
 * @property string|null $BirimKey3
 * @property string|null $created_at
 * @property string|null $updated_at
 * @property int|null $aktif
 * @property int|null $marka_id
 * @property int|null $kategori_id
 * @property int|null $grup_id
 * @property string|null $mcat
 * @property string|null $cat
 * @property string|null $subcat
 * @property int|null $qty
 * @property string|null $size
 * @property string|null $unitkg
 * @property int|null $palletqty
 * @property string|null $HSCode
 * @property string|null $rafkoridor
 * @property int|null $rafno
 * @property string|null $rafkat
 * @property int|null $rafomru
 * @property string|null $imsrc
 * @property string|null $Barcode1
 * @property string|null $Barcode2
 * @property string|null $Barcode3
 * @property string|null $Barcode4
 * @property string|null $Barcode5
 * @property string|null $Barcode6
 * @property string|null $Barcode7
 * @property string|null $Barcode8
 * @property string|null $Barcode9
 * @property string|null $Barcode10
 * @property string|null $Barcode11
 * @property string|null $Barcode12
 * @property string|null $Barcode13
 * @property string|null $Barcode14
 * @property string|null $Barcode15
 * @property string|null $PackFiyati
 * @property int|null $fiyat4
 * @property int|null $fiyat5
 * @property int|null $fiyat6
 * @property int|null $fiyat7
 * @property int|null $fiyat8
 * @property int|null $fiyat9
 * @property int|null $fiyat10
 * @property int|null $Palet
 * @property int|null $Layer
 * @property string|null $_key
 * @property string|null $marka
 */
class Urunler extends \yii\db\ActiveRecord
{


    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'urunler';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['StokKodu', 'AdetFiyati', 'KutuFiyati', 'Pm1', 'Pm2', 'Pm3', 'Vat', 'Birim1', 'BirimKey1', 'Birim2', 'BirimKey2', 'Birim3', 'BirimKey3',
                'marka_id', 'kategori_id', 'grup_id', 'qty', 'size', 'unitkg', 'palletqty', 'HSCode',
                'rafkoridor', 'rafno', 'rafkat', 'rafomru', 'imsrc', 'PackFiyati', 'Barcode1', 'Barcode2', 'Barcode3',
                'Barcode4', 'Barcode5', 'Barcode6', 'Barcode7', 'Barcode8', 'Barcode9', 'Barcode10',
                'Barcode11', 'Barcode12', 'Barcode13', 'Barcode14', 'Barcode15',
                'fiyat4', 'fiyat5', 'fiyat6', 'fiyat7', 'fiyat8', '_key', 'fiyat9', 'fiyat10', 'Palet', 'Layer'], 'default', 'value' => null],
            [['aktif'], 'default', 'value' => 1],
            [['UrunAdi'], 'required'],
            [['UrunId', 'BirimKey1', 'BirimKey2', 'aktif', 'marka_id', 'kategori_id', 'grup_id', 'qty', 'palletqty', 'rafno', 'rafomru',
                'fiyat4', 'fiyat5', 'fiyat6', 'fiyat7', 'fiyat8', 'fiyat9', 'fiyat10', 'Palet', 'Layer'], 'integer'],
            [['AdetFiyati', 'KutuFiyati', 'Pm1', 'Pm2', 'Pm3', 'Vat', 'unitkg', 'PackFiyati'], 'number'],
            [['created_at', 'updated_at'], 'safe'],
            [['_key'], 'string', 'max' => 10],
            [['StokKodu', 'Birim1', 'Birim2'], 'string', 'max' => 50],
            [['Birim3'], 'string', 'max' => 45],
            [['BirimKey3'], 'string', 'max' => 50],
            [['mcat', 'cat', 'subcat', 'marka'], 'string', 'max' => 120],
            [['UrunAdi', 'HSCode', 'Barcode1', 'Barcode2', 'Barcode3'], 'string', 'max' => 255],
            [['Barcode4'], 'string', 'max' => 45],
            [['imsrc'], 'string', 'max' => 255],
            [['size', 'rafkoridor', 'rafkat'], 'string', 'max' => 15],
            [['Barcode5', 'Barcode6', 'Barcode7', 'Barcode8', 'Barcode9', 'Barcode10',
              'Barcode11', 'Barcode12', 'Barcode13', 'Barcode14', 'Barcode15'], 'string', 'max' => 45],
            [['StokKodu'], 'unique'],
            [['UrunId'], 'unique'],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'UrunId' => 'Product ID',
            'StokKodu' => 'Stock Code',
            'UrunAdi' => 'Product Name',
            '_key' => 'Key',
            'AdetFiyati' => 'Qty Price',
            'KutuFiyati' => 'Box Price',
            'Pm1' => 'Pm1',
            'Pm2' => 'Pm2',
            'Pm3' => 'Pm3',
            'Vat' => 'Vat',
            'Birim1' => 'Unit 1',
            'BirimKey1' => 'Unit Key 1',
            'Birim2' => 'Unit 2',
            'BirimKey2' => 'Unit Key 2',
            'Birim3' => 'Unit 3',
            'BirimKey3' => 'Unit Key 3',
            'created_at' => 'Created At',
            'updated_at' => 'Updated At',
            'aktif' => 'Active',
            'marka_id' => 'Brand ID',
            'kategori_id' => 'Category ID',
            'grup_id' => 'Group ID',
            'mcat' => 'Main Category',
            'cat' => 'Category',
            'subcat' => 'Sub Category',
            'qty' => 'Quantity',
            'size' => 'Size',
            'unitkg' => 'Unit KG',
            'palletqty' => 'Pallet Quantity',
            'HSCode' => 'HS Code',
            'rafkoridor' => 'Shelf Corridor',
            'rafno' => 'Shelf No',
            'rafkat' => 'Shelf Level',
            'rafomru' => 'Shelf Life (Days)',
            'imsrc' => 'Image Source',
            'Barcode1' => 'Barcode 1',
            'Barcode2' => 'Barcode 2',
            'Barcode3' => 'Barcode 3',
            'Barcode4' => 'Barcode 4',
            'Barcode5' => 'Barcode 5',
            'Barcode6' => 'Barcode 6',
            'Barcode7' => 'Barcode 7',
            'Barcode8' => 'Barcode 8',
            'Barcode9' => 'Barcode 9',
            'Barcode10' => 'Barcode 10',
            'Barcode11' => 'Barcode 11',
            'Barcode12' => 'Barcode 12',
            'Barcode13' => 'Barcode 13',
            'Barcode14' => 'Barcode 14',
            'Barcode15' => 'Barcode 15',
            'PackFiyati' => 'Pack Price',
            'fiyat4' => 'Price 4',
            'fiyat5' => 'Price 5',
            'fiyat6' => 'Price 6',
            'fiyat7' => 'Price 7',
            'fiyat8' => 'Price 8',
            'fiyat9' => 'Price 9',
            'fiyat10' => 'Price 10',
            'Palet' => 'Pallet',
            'Layer' => 'Layer',
        ];
    }
    public function getMarka(){
        return $this->hasOne(Marka::class, ['id' => 'marka_id']);
    }
    public function getGrup(){
        return $this->hasOne(Grup::class, ['id' => 'grup_id']);
    }
    public function getKategori(){
        return $this->hasOne(Kategori::class, ['id' => 'kategori_id']);
    }

    public function getBirimler()
    {
        return $this->hasMany(Birimler::class, ['StokKodu' => 'StokKodu']);
    }

    public function getTedarikci(){
        return $this->hasMany(UrunTedarikci::class, ['stokkodu' => 'StokKodu'],);
    }
    public function getTedarikciList(){
        return $this->getTedarikci()
            ->joinWith('tedarikci')
            ->select(['tedarikci.tedarikci_kodu', 'tedarikci.tedarikci_adi'])
            ->asArray()
            ->all();
    }
}
