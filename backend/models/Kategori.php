<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "kategori".
 *
 * @property int $id
 * @property string|null $kategori
 * @property int $aktif
 */
class Kategori extends \yii\db\ActiveRecord
{


    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'kategori';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['kategori'], 'default', 'value' => null],
            [['aktif'], 'default', 'value' => 1],
            [['aktif'], 'integer'],
            [['kategori'], 'string', 'max' => 120],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => 'ID',
            'kategori' => 'Category',
            'aktif' => 'Active',
        ];
    }

    /**
     * Returns list of active categories for dropdown
     * @return array
     */
    public static function getKategoriList()
    {
        return \yii\helpers\ArrayHelper::map(self::find()->where(['aktif' => 1])->all(), 'id', 'adi');
    }

}
