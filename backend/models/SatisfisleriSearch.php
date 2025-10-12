<?php

namespace app\models;

use yii\base\Model;
use yii\data\ActiveDataProvider;
use app\models\Satisfisleri;

/**
 * SatisfisleriSearch represents the model behind the search form of `app\models\Satisfisleri`.
 */
class SatisfisleriSearch extends Satisfisleri
{
    /**
     * {@inheritdoc}
     */
    public $unvan;
    public $total_amount;
    public $groupByCustomer = true;
    /**
     * cash_session filtre durumu: 'null' | 'not_null' | 'any'
     */
    public $cashSessionState = 'any';
    public function rules()
    {
        return [
            [['FisId', 'SyncStatus'], 'integer'],
            [['MusteriId', 'FisNo', 'Fistarihi', 'OdemeTuru', 'status', 'LastSyncTime', 'unvan', 'CekNo', 'CekTarih'], 'safe'],
            [['Toplamtutar', 'NakitOdeme', 'KartOdeme', 'CekOdeme', 'total_amount'], 'number'],
            [['cash_session_id', 'kaynak'], 'integer'],
            [['cashSessionState'], 'in', 'range' => ['null', 'not_null', 'any']],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function scenarios()
    {
        // bypass scenarios() implementation in the parent class
        return Model::scenarios();
    }

    /**
     * Creates data provider instance with search query applied
     *
     * @param array $params
     * @param string|null $formName Form name to be used into `->load()` method.
     *
     * @return ActiveDataProvider
     */
    public function search($params, $formName = null)
    {
        $query = Satisfisleri::find()
            ->alias('sf')
            ->joinWith('musteri')
            ;

        // cash_session filtresini controller belirler
        if ($this->cashSessionState === 'null') {
            $query->andWhere('sf.cash_session_id IS NULL');
        } elseif ($this->cashSessionState === 'not_null') {
            $query->andWhere('sf.cash_session_id IS NOT NULL');
        }

        // kaynak filtresi: grup bazlı görünümde de uygulanmalı
        $query->andFilterWhere(['sf.kaynak' => $this->kaynak]);

        if ($this->groupByCustomer) {
            $query->select([
                'sf.MusteriId AS MusteriId',
                'musteriler.Unvan AS unvan',
                new \yii\db\Expression('SUM(sf.Toplamtutar) AS total_amount')
            ])->groupBy(['sf.MusteriId', 'musteriler.Unvan']);
        }

        // add conditions that should always apply here

        $dataProvider = new ActiveDataProvider([
            'query' => $query,
            'sort' => $this->groupByCustomer
                ? [
                    'defaultOrder' => [
                        'total_amount' => SORT_DESC,
                    ],
                    'attributes' => [
                        'MusteriId',
                        'unvan',
                        'total_amount' => [
                            'asc' => ['total_amount' => SORT_ASC],
                            'desc' => ['total_amount' => SORT_DESC],
                            'label' => 'Total Amount',
                        ],
                    ],
                ]
                : [
                    'defaultOrder' => [
                        'FisId' => SORT_DESC,
                    ],
                ],
        ]);

        $this->load($params, $formName);

        if (!$this->validate()) {
            // uncomment the following line if you do not want to return any records when validation fails
            // $query->where('0=1');
            return $dataProvider;
        }

        if ($this->groupByCustomer) {
            // filtering for grouped results
            $query->andFilterWhere(['like', 'sf.MusteriId', $this->MusteriId])
                ->andFilterWhere(['like', 'musteriler.Unvan', $this->unvan]);
        } else {
            // grid filtering conditions (per-invoice)
            $query->andFilterWhere([
                'FisId' => $this->FisId,
                'Fistarihi' => $this->Fistarihi,
                'MusteriId' => $this->MusteriId,
                'Toplamtutar' => $this->Toplamtutar,
                'NakitOdeme' => $this->NakitOdeme,
                'KartOdeme' => $this->KartOdeme,
                'SyncStatus' => $this->SyncStatus,
                'LastSyncTime' => $this->LastSyncTime,
                'CekOdeme' => $this->CekOdeme,
                'CekTarih' => $this->CekTarih,
                'cash_session_id' => $this->cash_session_id,
                'kaynak' => $this->kaynak,
            ]);

            $query->andFilterWhere(['like', 'FisNo', $this->FisNo])
                ->andFilterWhere(['like', 'OdemeTuru', $this->OdemeTuru])
                ->andFilterWhere(['like', 'musteriler.Unvan', $this->unvan])
                ->andFilterWhere(['like', 'status', $this->status])
                ->andFilterWhere(['like', 'CekNo', $this->CekNo]);
        }
        return $dataProvider;
    }
}
